//! Generates `small`/`medium`/`large` resized copies of a `Media` item's original upload via the
//! system `ImageMagick` install (`magick`, or the legacy `convert`+`identify` pair) for images, or
//! `ffmpeg`/`ffprobe` for video, storing them in MinIO alongside the original and recording their
//! paths in `Media.converted_sizes`. The same dimension probe also records `Media.aspect_ratio`.
//! Used by `bin/convert_media_sizes.rs`.
//!
//! Only PNG/JPEG are converted for images (`CONVERTIBLE_CONTENT_TYPES`) and MP4/QuickTime/WebM for
//! video (`VIDEO_CONVERTIBLE_CONTENT_TYPES`) for now -- both tools handle other common formats
//! fine, but we don't have callers needing them yet.

use std::path::{Path, PathBuf};
use std::process::Command;

use anyhow::{bail, Context, Result};
use diesel::*;
use s3::Bucket;

use crate::db_connection::PgPooledConnection;
use crate::models::{ConvertedSize, ConvertedSizeSpec, ConvertedSizes, Media};
use crate::schema::media;

pub const CONVERTIBLE_CONTENT_TYPES: [&str; 3] = ["image/png", "image/jpeg", "image/jpg"];
pub const VIDEO_CONVERTIBLE_CONTENT_TYPES: [&str; 3] =
    ["video/mp4", "video/quicktime", "video/webm"];

fn is_video_content_type(content_type: &str) -> bool {
    VIDEO_CONVERTIBLE_CONTENT_TYPES.contains(&content_type)
}

/// `Media` rows still needing conversion: not yet `processed`, or missing `aspect_ratio` (e.g.
/// `processed` media left over from before that column existed -- see `convert_media`'s backfill
/// path), and a content type we know how to convert. `processed` is only ever set once conversion
/// (successfully) completes, so this naturally retries anything a prior run errored out on
/// (including runs where the relevant tool, `ImageMagick` or `ffmpeg`, was missing).
pub fn media_pending_conversion(
    conn: &mut PgPooledConnection,
    limit: i64,
) -> QueryResult<Vec<Media>> {
    let content_types: Vec<&str> = CONVERTIBLE_CONTENT_TYPES
        .iter()
        .chain(VIDEO_CONVERTIBLE_CONTENT_TYPES.iter())
        .copied()
        .collect();
    media::table
        .filter(media::processed.eq(false).or(media::aspect_ratio.is_null()))
        .filter(media::content_type.eq_any(content_types))
        .order(media::id.asc())
        .limit(limit)
        .load::<Media>(conn)
}

/// Which `ImageMagick` command layout is on `$PATH`: v7 unifies everything under a single
/// `magick` binary (`magick identify ...`, `magick in.png -resize ... out.png`), while v6 (and
/// some v7 compat installs) only provide the separate legacy `convert`/`identify` binaries.
pub struct ImageMagick {
    modern: bool,
}

impl ImageMagick {
    /// Returns `None` if neither command layout is available -- callers should log and skip
    /// conversion entirely rather than fail hard, since ImageMagick is an optional dependency
    /// (see docs/README's "Prerequisites for your $PATH").
    pub fn detect() -> Option<Self> {
        if command_exists("magick") {
            Some(Self { modern: true })
        } else if command_exists("convert") && command_exists("identify") {
            Some(Self { modern: false })
        } else {
            None
        }
    }

    fn identify_command(&self) -> Command {
        if self.modern {
            let mut command = Command::new("magick");
            command.arg("identify");
            command
        } else {
            Command::new("identify")
        }
    }

    fn convert_command(&self) -> Command {
        if self.modern {
            Command::new("magick")
        } else {
            Command::new("convert")
        }
    }

    fn dimensions(&self, path: &Path) -> Result<(u32, u32)> {
        let output = self
            .identify_command()
            .arg("-format")
            .arg("%w %h")
            .arg(path)
            .output()
            .context("failed to run identify")?;
        if !output.status.success() {
            bail!(
                "identify exited with {}: {}",
                output.status,
                String::from_utf8_lossy(&output.stderr)
            );
        }
        let stdout = String::from_utf8_lossy(&output.stdout);
        let mut parts = stdout.split_whitespace();
        let width: u32 = parts.next().context("missing width")?.parse()?;
        let height: u32 = parts.next().context("missing height")?.parse()?;
        Ok((width, height))
    }

    /// Resizes `input` to fit within `max_dimension`x`max_dimension`, preserving aspect ratio and
    /// never upscaling (ImageMagick's `>` geometry flag), stripping EXIF/color-profile metadata,
    /// and correcting orientation from EXIF before doing so.
    fn resize(&self, input: &Path, output: &Path, max_dimension: u32) -> Result<()> {
        let status = self
            .convert_command()
            .arg(input)
            .arg("-auto-orient")
            .arg("-strip")
            .arg("-resize")
            .arg(format!("{0}x{0}>", max_dimension))
            .arg(output)
            .status()
            .context("failed to run convert")?;
        if !status.success() {
            bail!("convert exited with {}", status);
        }
        Ok(())
    }
}

/// Resizes video `Media` via a system `ffmpeg`/`ffprobe` install.
pub struct FFmpeg;

impl FFmpeg {
    /// Returns `None` if `ffmpeg` or `ffprobe` aren't both on `$PATH` -- callers should log and
    /// skip video conversion entirely rather than fail hard, since ffmpeg is an optional
    /// dependency (see docs/README's "Prerequisites for your $PATH"), same as `ImageMagick`.
    pub fn detect() -> Option<Self> {
        if command_exists("ffmpeg") && command_exists("ffprobe") {
            Some(Self)
        } else {
            None
        }
    }

    fn dimensions(&self, path: &Path) -> Result<(u32, u32)> {
        let output = Command::new("ffprobe")
            .arg("-v")
            .arg("error")
            .arg("-select_streams")
            .arg("v:0")
            .arg("-show_entries")
            .arg("stream=width,height")
            .arg("-of")
            .arg("csv=s=x:p=0")
            .arg(path)
            .output()
            .context("failed to run ffprobe")?;
        if !output.status.success() {
            bail!(
                "ffprobe exited with {}: {}",
                output.status,
                String::from_utf8_lossy(&output.stderr)
            );
        }
        let stdout = String::from_utf8_lossy(&output.stdout);
        let mut parts = stdout.trim().split('x');
        let width: u32 = parts.next().context("missing width")?.parse()?;
        let height: u32 = parts.next().context("missing height")?.parse()?;
        Ok((width, height))
    }

    /// Resizes `input` to fit within `max_dimension`x`max_dimension`, preserving aspect ratio and
    /// never upscaling (the `min(N,iw/ih)` scale filter, mirroring `ImageMagick::resize`'s `>`
    /// geometry flag), re-encoding with a codec appropriate to `content_type`'s container.
    fn resize(
        &self,
        input: &Path,
        output: &Path,
        max_dimension: u32,
        content_type: &str,
    ) -> Result<()> {
        let mut command = Command::new("ffmpeg");
        command
            .arg("-y")
            .arg("-nostdin")
            .arg("-i")
            .arg(input)
            .arg("-vf")
            .arg(format!(
                "scale='min({0},iw)':'min({0},ih)':force_original_aspect_ratio=decrease:force_divisible_by=2",
                max_dimension
            ));
        if content_type == "video/webm" {
            command.args([
                "-c:v",
                "libvpx-vp9",
                "-b:v",
                "0",
                "-crf",
                "32",
                "-c:a",
                "libopus",
            ]);
        } else {
            command.args([
                "-c:v",
                "libx264",
                "-preset",
                "veryfast",
                "-crf",
                "23",
                "-c:a",
                "aac",
                "-movflags",
                "+faststart",
            ]);
        }
        let status = command
            .arg(output)
            .status()
            .context("failed to run ffmpeg")?;
        if !status.success() {
            bail!("ffmpeg exited with {}", status);
        }
        Ok(())
    }
}

fn command_exists(program: &str) -> bool {
    Command::new(program)
        .arg("-version")
        .output()
        .map(|output| output.status.success())
        .unwrap_or(false)
}

fn extension_for_content_type(content_type: &str) -> Result<&'static str> {
    match content_type {
        "image/png" => Ok("png"),
        "image/jpeg" | "image/jpg" => Ok("jpg"),
        "video/mp4" => Ok("mp4"),
        "video/quicktime" => Ok("mov"),
        "video/webm" => Ok("webm"),
        other => bail!("unsupported content type: {other}"),
    }
}

/// Which tool converts a given `Media` item, chosen by its content type.
enum Converter<'a> {
    Image(&'a ImageMagick),
    Video(&'a FFmpeg),
}

impl Converter<'_> {
    fn dimensions(&self, path: &Path) -> Result<(u32, u32)> {
        match self {
            Converter::Image(imagemagick) => imagemagick.dimensions(path),
            Converter::Video(ffmpeg) => ffmpeg.dimensions(path),
        }
    }

    fn resize(
        &self,
        input: &Path,
        output: &Path,
        max_dimension: u32,
        content_type: &str,
    ) -> Result<()> {
        match self {
            Converter::Image(imagemagick) => imagemagick.resize(input, output, max_dimension),
            Converter::Video(ffmpeg) => ffmpeg.resize(input, output, max_dimension, content_type),
        }
    }
}

/// Downloads `item`'s original from MinIO, generates any `ConvertedSizeSpec` it's larger than
/// (skipping sizes it already fits within -- those fall back to the original), uploads the
/// results back to MinIO next to the original, and marks `item` `processed`.
///
/// `imagemagick`/`ffmpeg` are `None` when the respective tool wasn't found on `$PATH` at startup;
/// converting a `Media` item that needs the missing one fails (and is retried next run) without
/// affecting items convertible by the other.
pub async fn convert_media(
    item: &Media,
    imagemagick: Option<&ImageMagick>,
    ffmpeg: Option<&FFmpeg>,
    bucket: &Bucket,
    tmp_dir: &Path,
    conn: &mut PgPooledConnection,
) -> Result<()> {
    let converter = if is_video_content_type(&item.content_type) {
        Converter::Video(ffmpeg.context("ffmpeg not found on $PATH; cannot convert video Media")?)
    } else {
        Converter::Image(
            imagemagick.context("ImageMagick not found on $PATH; cannot convert image Media")?,
        )
    };

    let extension = extension_for_content_type(&item.content_type)?;
    let input_path: PathBuf = tmp_dir.join(format!("{}-original.{}", item.id, extension));

    let original = bucket
        .get_object(&item.minio_path)
        .await
        .context("failed to download original from MinIO")?;
    std::fs::write(&input_path, original.as_slice())?;

    let (width, height) = converter.dimensions(&input_path)?;
    let aspect_ratio = width as f32 / height as f32;

    if item.processed {
        // Backfill path: `converted_sizes` was already generated by a prior run, before
        // `aspect_ratio` existed (see `media_pending_conversion`) -- just record it, without
        // redoing the (potentially expensive) resize/upload work above.
        let _ = std::fs::remove_file(&input_path);
        diesel::update(media::table.find(item.id))
            .set(media::aspect_ratio.eq(aspect_ratio))
            .execute(conn)?;
        return Ok(());
    }

    let mut sizes = ConvertedSizes::default();

    for spec in ConvertedSizeSpec::ALL {
        if width.max(height) <= spec.max_dimension() {
            log::info!(
                "Media {} ({}x{}) already fits within '{}' ({}px) -- skipping",
                item.id,
                width,
                height,
                spec.key(),
                spec.max_dimension()
            );
            continue;
        }

        let output_path = tmp_dir.join(format!("{}-{}.{}", item.id, spec.key(), extension));
        converter.resize(
            &input_path,
            &output_path,
            spec.max_dimension(),
            &item.content_type,
        )?;
        let output_bytes = std::fs::read(&output_path)?;
        let _ = std::fs::remove_file(&output_path);

        let converted_minio_path = format!("{}.{}", item.minio_path, spec.key());
        bucket
            .put_object_with_content_type(&converted_minio_path, &output_bytes, &item.content_type)
            .await
            .context("failed to upload converted size to MinIO")?;

        log::info!(
            "Media {}: generated '{}' ({} bytes) at {}",
            item.id,
            spec.key(),
            output_bytes.len(),
            converted_minio_path
        );
        sizes.set(
            spec,
            ConvertedSize {
                minio_path: converted_minio_path,
                content_type: item.content_type.clone(),
            },
        );
    }

    let _ = std::fs::remove_file(&input_path);

    diesel::update(media::table.find(item.id))
        .set((
            media::converted_sizes.eq(serde_json::to_value(&sizes)?),
            media::processed.eq(true),
            media::aspect_ratio.eq(aspect_ratio),
        ))
        .execute(conn)?;

    Ok(())
}
