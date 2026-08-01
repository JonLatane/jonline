//! Generates `small`/`medium`/`large` resized copies of a `Media` item's original upload via the
//! system `ImageMagick` install (`magick`, or the legacy `convert`+`identify` pair), storing them
//! in MinIO alongside the original and recording their paths in `Media.converted_sizes`. Used by
//! `bin/convert_media_sizes.rs`.
//!
//! Only PNG/JPEG are converted for now (`CONVERTIBLE_CONTENT_TYPES`) -- both tools handle other
//! common formats fine, but we don't have callers needing them yet.

use std::path::{Path, PathBuf};
use std::process::Command;

use anyhow::{bail, Context, Result};
use diesel::*;
use s3::Bucket;

use crate::db_connection::PgPooledConnection;
use crate::models::{ConvertedSize, ConvertedSizeSpec, ConvertedSizes, Media};
use crate::schema::media;

pub const CONVERTIBLE_CONTENT_TYPES: [&str; 3] = ["image/png", "image/jpeg", "image/jpg"];

/// `Media` rows still needing conversion: not yet `processed`, and a content type we know how to
/// convert. `processed` is only ever set once conversion (successfully) completes, so this
/// naturally retries anything a prior run errored out on.
pub fn media_pending_conversion(
    conn: &mut PgPooledConnection,
    limit: i64,
) -> QueryResult<Vec<Media>> {
    media::table
        .filter(media::processed.eq(false))
        .filter(media::content_type.eq_any(CONVERTIBLE_CONTENT_TYPES))
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
        other => bail!("unsupported content type: {other}"),
    }
}

/// Downloads `item`'s original from MinIO, generates any `ConvertedSizeSpec` it's larger than
/// (skipping sizes it already fits within -- those fall back to the original), uploads the
/// results back to MinIO next to the original, and marks `item` `processed`.
pub async fn convert_media(
    item: &Media,
    imagemagick: &ImageMagick,
    bucket: &Bucket,
    tmp_dir: &Path,
    conn: &mut PgPooledConnection,
) -> Result<()> {
    let extension = extension_for_content_type(&item.content_type)?;
    let input_path: PathBuf = tmp_dir.join(format!("{}-original.{}", item.id, extension));

    let original = bucket
        .get_object(&item.minio_path)
        .await
        .context("failed to download original from MinIO")?;
    std::fs::write(&input_path, original.as_slice())?;

    let (width, height) = imagemagick.dimensions(&input_path)?;
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
        imagemagick.resize(&input_path, &output_path, spec.max_dimension())?;
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
        ))
        .execute(conn)?;

    Ok(())
}
