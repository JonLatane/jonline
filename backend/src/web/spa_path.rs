//! `SpaPath`: Rocket's `PathBuf` path guard, minus one rule that breaks real Rellm URLs.
//!
//! `PathBuf`'s `FromSegments` refuses any path with a segment that *ends in `:`* (a Windows drive-letter
//! precaution). A short Post URL to a Bluesky post, `/~did:plc:…~rkey@bluesky:`, ends in exactly that -- so the
//! SPA catch-alls (`spa_file_or_username_or_custom_tab`, `elm_file`), which serve every client-side route, forwarded
//! it to a 422 instead of the app, while `/post/did:plc:…~rkey@bluesky:` (a route with its own `<id>` segment, not
//! a `PathBuf`) worked.
//!
//! Everything else `PathBuf` guards against is kept, so a `SpaPath` is just as safe to join onto a directory:
//! dotfile segments, a leading `*`, a trailing `<`/`>`, an embedded `/` (from a decoded `%2F`), and -- on Windows
//! only, where it really is a drive-letter hazard -- any `:` or `\`. `..` pops, as it does for `PathBuf`.

use std::path::PathBuf;

use rocket::http::uri::{Segments, error::PathError, fmt::Path};
use rocket::request::FromSegments;

pub struct SpaPath(pub PathBuf);

impl<'r> FromSegments<'r> for SpaPath {
    type Error = PathError;

    fn from_segments(segments: Segments<'r, Path>) -> Result<Self, Self::Error> {
        path_from_segments(segments).map(SpaPath)
    }
}

/// `Segments::to_path_buf(false)`, except that a segment may end in `:` (see the module docs). Takes plain
/// strings so it can be tested without building a request.
pub fn path_from_segments<S: AsRef<str>>(
    segments: impl IntoIterator<Item = S>,
) -> Result<PathBuf, PathError> {
    let mut buf = PathBuf::new();
    for segment in segments {
        let segment = segment.as_ref();
        if segment == ".." {
            buf.pop();
        } else if segment.starts_with('.') {
            return Err(PathError::BadStart('.'));
        } else if segment.starts_with('*') {
            return Err(PathError::BadStart('*'));
        } else if segment.ends_with('>') {
            return Err(PathError::BadEnd('>'));
        } else if segment.ends_with('<') {
            return Err(PathError::BadEnd('<'));
        } else if segment.contains('/') {
            return Err(PathError::BadChar('/'));
        } else if cfg!(windows) && segment.contains('\\') {
            return Err(PathError::BadChar('\\'));
        } else if cfg!(windows) && segment.contains(':') {
            return Err(PathError::BadChar(':'));
        } else {
            buf.push(segment);
        }
    }
    Ok(buf)
}
