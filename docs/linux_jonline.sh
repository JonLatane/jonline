#!/bin/bash
#
# Source of truth for the self-updating `jonline` launcher script shipped as
# `bin/jonline` in the Linux release tarball (jonline-<version>-linux.tar.bz2).
#
# This file is copied verbatim into the tarball's `bin/jonline` (chmod +x'd)
# by the "Assemble Linux release tarball" step of the Server CI/CD workflow
# (create_linux_release job) in .github/workflows/server_ci_cd.yml -- don't
# hand-edit a downloaded tarball's bin/jonline, edit this file instead.
#
# The one placeholder below, @@JONLINE_PACKAGE_BASE_DIR@@, is replaced by
# that CI step with a literal default install directory (unexpanded shell
# syntax, e.g. `$HOME/.jonline-linux`), resolved at runtime relative to
# whichever user's $HOME the script actually runs under -- so aside from
# that one substitution, this file is plain, valid, directly-runnable bash
# (e.g. `bash docs/linux_jonline.sh help` works locally; `install`, `update`,
# and `cleanup_updates` are the only subcommands that need the real
# substitution, since they manage the *canonical* install location -- every
# other command (server, version, ...) locates the package from its own
# `bin/jonline` path instead, so it works from wherever the tarball was
# extracted, until/unless `install` moves it to the canonical location.
#
set -euo pipefail

JONLINE_RELEASES_REPO="jonlatane/jonline"

JONLINE_ENV="$HOME/.jonline"
if [ ! -f "$JONLINE_ENV" ]; then
  cat > "$JONLINE_ENV" <<'JONLINE_ENV_EOF'
DATABASE_URL=postgres://localhost/jonline_dev

MINIO_ENDPOINT=http://localhost:9000
MINIO_REGION=
MINIO_BUCKET=jonline-dev
MINIO_ACCESS_KEY=ROOTNAME
MINIO_SECRET_KEY=CHANGEME123

# TLS_CERT_PATH=/path/to/cert.pem
JONLINE_ENV_EOF
fi

set -a
source "$JONLINE_ENV"
set +a

JONLINE_DB_NAME="${JONLINE_DB_NAME:-jonline_dev}"
JONLINE_MINIO_CONTAINER="${JONLINE_MINIO_CONTAINER:-jonline-dev-minio}"
JONLINE_MINIO_DATA_DIR="${JONLINE_MINIO_DATA_DIR:-$HOME/.jonline-minio-data}"

jonline_help() {
  cat <<'JONLINE_HELP_EOF'
jonline - launcher for the Jonline server and its local dev dependencies

Usage: jonline <command> [args...]

Relies on Postgres's createdb/dropdb/psql for its example database (local_db_* commands),
and on Docker's docker for its example MinIO (local_minio_* commands; S3-compatible storage).

Relies on `jq` and `curl` for its self-updating commands (install, show_latest, update, cleanup_updates).

Edit ~/.jonline (created on first run) to point DATABASE_URL, MINIO_* and other environment
variables at different instances, if desired. (Or use "jonline edit_environment".)

Start server:
  jonline server

Quick setup:
  jonline local_db_create && jonline local_minio_create && jonline server

Commands:

  Core/Lifecycle:

    server                   Run the Jonline server (jonline-server)
    version                  Print the Jonline server version (jonline-server --version)
    local_instances_stop     Stop any running jonline-server processes
    help                     Show this help text

  Environment/Configuration:

    environment              Print the current config (cat ~/.jonline)
    edit_environment         Edit the config in $EDITOR (falls back to vi)

  Example Environment (will match generated default generated ~/.jonline):

    local_db_create          Create a local Postgres database (createdb jonline_dev)
    local_db_drop            Drop the local Postgres database (dropdb jonline_dev)
    local_db_reset           Stop local instances, then drop and recreate the local database
    local_db_connect         Connect to the local database with psql ($DATABASE_URL)

    local_minio_start        Start an existing local MinIO docker container
    local_minio_create       Start local MinIO, creating its docker container first if needed
    local_minio_delete       Stop and remove the local MinIO docker container

  Background jobs:

    delete_expired_tokens    Delete expired auth tokens from the database
    delete_unowned_media     Delete media no longer referenced by any post/user/etc.
    generate_preview_images  Generate media preview images -- requires Brave Browser
                             installed at /usr/bin/brave-browser (e.g. `apt install
                             brave-browser`) plus ad/cookie-blocking Chrome extensions
                             unpacked at /opt/preview_generator_extensions/{ublock,nocookies}/
                             -- neither is set up by this script; see
                             deploys/docker/preview_generator/Dockerfile for a reference setup

  Admin tools:

    set_permission           Grant/revoke a global permission for a user by username
                             e.g.: jonline set_permission <my_admin_username> admin on
    delete_preview_images    Delete generated preview images, e.g. to force regeneration
    disable_cdn_grpc         Disable the experimental gRPC CDN settings, as an "escape hatch" in case you 
                             mess up your CDN configuration in the web UI and lose gRPC access.

  Utilities:

    to_db_id                 Convert a proto (external, string) ID to a database (internal) ID
    to_proto_id              Convert a database (internal) ID to a proto (external, string) ID
    grpcurl                  Run the bundled grpcurl. "Like curl, but for gRPC."
                             (https://github.com/fullstorydev/grpcurl)

  Linux self-updater subcommands (require `curl` and/or `jq`):

    install                  Move this jonline folder to its canonical location
                             (@@JONLINE_PACKAGE_BASE_DIR@@), required once before `update` works
    show_latest              Print the latest Jonline release version available on GitHub
    update                   Download the latest release and install it to @@JONLINE_PACKAGE_BASE_DIR@@, 
                             backing up the current install first (requires `install` first)
    cleanup_updates          Delete backups/downloads accumulated by `update`, freeing disk space
    uninstall                Delete @@JONLINE_PACKAGE_BASE_DIR@@ entirely, after confirming (press y)


  Every command except `update`/`cleanup_updates` works from wherever you put
  the extracted `jonline` folder -- `install` is only needed to opt into `update`.
JONLINE_HELP_EOF
}

local_db_create() {
  createdb "$JONLINE_DB_NAME"
}

local_db_drop() {
  dropdb "$JONLINE_DB_NAME"
}

local_db_reset() {
  local_instances_stop
  local_db_drop
  local_db_create
}

local_db_connect() {
  psql "$DATABASE_URL"
}

local_minio_start() {
  docker start "$JONLINE_MINIO_CONTAINER"
}

local_minio_create() {
  local_minio_start || _do_local_minio_create
}

_do_local_minio_create() {
  mkdir -p "$JONLINE_MINIO_DATA_DIR"
  docker run -d -p 9000:9000 -p 9090:9090 --name "$JONLINE_MINIO_CONTAINER" -v "$JONLINE_MINIO_DATA_DIR:/data" -e "MINIO_ROOT_USER=$MINIO_ACCESS_KEY" -e "MINIO_ROOT_PASSWORD=$MINIO_SECRET_KEY" minio/minio server /data --console-address ":9090"
}

local_minio_delete() {
  docker stop "$JONLINE_MINIO_CONTAINER"
  docker rm "$JONLINE_MINIO_CONTAINER"
}

local_instances_stop() {
  killall jonline-server-amd64 jonline-server-arm64 || true
}

# Prints "amd64" or "arm64" to match the release asset/binary naming, or
# fails for architectures the Linux release doesn't build for (e.g. 32-bit x86).
_jonline_arch() {
  case "$(uname -m)" in
    x86_64|amd64)
      echo amd64
      ;;
    aarch64|arm64)
      echo arm64
      ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

# Deletes the arch-suffixed binaries (jonline-server-<arch>, grpcurl-<arch>,
# ...) that don't match this machine's architecture, e.g. removes every
# *-amd64 binary on an arm64 machine. Used by `install`/`update` since the
# release package ships binaries for every built architecture side-by-side,
# but only one of each pair is ever needed on a given machine.
_jonline_delete_foreign_arch_binaries() {
  local dir="$1"
  local other_arch
  case "$(_jonline_arch)" in
    amd64) other_arch=arm64 ;;
    arm64) other_arch=amd64 ;;
  esac
  rm -f "$dir"/*-"$other_arch"
}

# Resolves the package root (the dir containing jonline-server-<arch>, docs/,
# tamagui_web/, etc.) from this script's own location, i.e. wherever the
# tarball happens to be extracted -- `readlink -f` follows symlinks (e.g. a
# `ln -s .../bin/jonline /usr/local/bin/jonline`) so this still finds the
# real package dir rather than wherever the symlink itself lives.
_jonline_package_dir() {
  local script_path
  script_path="$(readlink -f "${BASH_SOURCE[0]}")"
  dirname "$(dirname "$script_path")"
}

# Shared by every command below that execs one of the package's arch-suffixed
# binaries (jonline-server-<arch>, delete_expired_tokens-<arch>, grpcurl-<arch>, ...).
_jonline_exec_bin() {
  local bin="$1"
  shift
  cd "$(_jonline_package_dir)" && exec "./${bin}-$(_jonline_arch)" "$@"
}

server() {
  _jonline_exec_bin jonline-server "$@"
}

version() {
  server --version
}

# Background jobs
delete_expired_tokens() {
  _jonline_exec_bin delete_expired_tokens "$@"
}

delete_unowned_media() {
  _jonline_exec_bin delete_unowned_media "$@"
}

# Renders media preview images headlessly. Requires Brave Browser at
# /usr/bin/brave-browser (apt install brave-browser) and ad/cookie-blocking
# Chrome extensions unpacked at /opt/preview_generator_extensions/{ublock,nocookies}/
# -- see deploys/docker/preview_generator/Dockerfile for a reference setup.
generate_preview_images() {
  _jonline_exec_bin generate_preview_images "$@"
}

# Admin tools
set_permission() {
  _jonline_exec_bin set_permission "$@"
}

delete_preview_images() {
  _jonline_exec_bin delete_preview_images "$@"
}

disable_cdn_grpc() {
  _jonline_exec_bin disable_cdn_grpc "$@"
}

# Utilities
to_db_id() {
  _jonline_exec_bin to_db_id "$@"
}

to_proto_id() {
  _jonline_exec_bin to_proto_id "$@"
}

grpcurl() {
  _jonline_exec_bin grpcurl "$@"
}

environment() {
  cat "$JONLINE_ENV"
}

edit_environment() {
  # Intentionally unquoted: $EDITOR may be multiple words (e.g. "code --wait").
  ${EDITOR:-vi} "$JONLINE_ENV"
}

# Requires `curl` and `jq`. Both just need to be installed -- reading
# public release metadata doesn't require any authentication.
_jonline_latest_release_json() {
  curl -sf "https://api.github.com/repos/${JONLINE_RELEASES_REPO}/releases/latest"
}

show_latest() {
  _jonline_latest_release_json | jq -r '.tag_name'
}

# `update` and `cleanup_updates` only ever manage this fixed location -- not
# wherever the package the running script belongs to happens to live -- so
# that repeated updates land in one place instead of scattering across
# however many folders someone's extracted a tarball into over time.
install() {
  local base="@@JONLINE_PACKAGE_BASE_DIR@@"
  local pkg_dir
  pkg_dir="$(_jonline_package_dir)"

  if [ "$pkg_dir" = "$base" ]; then
    echo "Already installed at $base."
    return 0
  fi

  if [ -e "$base" ]; then
    local installed_version="unknown version"
    if [ -f "$base/version" ]; then
      installed_version="v$(cat "$base/version")"
    fi
    echo "$base already exists (${installed_version}). Remove it first if you want to replace it with this copy, or run 'jonline update' from within it instead." >&2
    exit 1
  fi

  mkdir -p "$(dirname "$base")"
  mv "$pkg_dir" "$base"
  _jonline_delete_foreign_arch_binaries "$base"
  echo "Installed to $base."
  echo "Run $base/bin/jonline server (consider adding $base/bin to your \$PATH)."
}

_jonline_require_installed() {
  local base="@@JONLINE_PACKAGE_BASE_DIR@@"
  if [ ! -f "$base/version" ]; then
    echo "Jonline isn't installed at $base yet." >&2
    echo "Run 'jonline install' first -- it moves this jonline folder to $base," >&2
    echo "the fixed location 'update' downloads new releases into." >&2
    exit 1
  fi
}

update() {
  _jonline_require_installed

  local base="@@JONLINE_PACKAGE_BASE_DIR@@"
  local updates_dir="$base/.updates"
  local arch
  arch="$(_jonline_arch)"

  local release_json
  release_json="$(_jonline_latest_release_json)"
  local latest_tag
  latest_tag="$(printf '%s' "$release_json" | jq -r '.tag_name')"
  local latest_version="${latest_tag#v}"

  local current_version="none"
  if [ -f "$base/version" ]; then
    current_version="$(cat "$base/version")"
  fi

  if [ "$current_version" = "$latest_version" ]; then
    echo "Already up to date (v${current_version})."
    return 0
  fi

  echo "Updating v${current_version} -> v${latest_version}..."

  mkdir -p "$updates_dir"

  # The release tarball is a single package containing binaries for every
  # built architecture (see $PKG/jonline-server-<arch> in create_linux_release) --
  # $arch just picks which one `server` execs, so the download itself isn't
  # per-arch. It's still validated up front so unsupported architectures fail
  # fast here instead of via a confusing exec failure from `server` later.
  local asset_name="jonline-${latest_version}-linux.tar.bz2"
  local sha_name="${asset_name}.sha256"
  local download_dir
  download_dir="$(mktemp -d)"

  local asset_url sha_url
  asset_url="$(printf '%s' "$release_json" | jq -r --arg name "$asset_name" '.assets[] | select(.name == $name) | .browser_download_url')"
  sha_url="$(printf '%s' "$release_json" | jq -r --arg name "$sha_name" '.assets[] | select(.name == $name) | .browser_download_url')"
  if [ -z "$asset_url" ] || [ -z "$sha_url" ]; then
    echo "Couldn't find $asset_name and/or $sha_name among the assets of release $latest_tag." >&2
    exit 1
  fi
  curl -sL -o "$download_dir/$asset_name" "$asset_url"
  curl -sL -o "$download_dir/$sha_name" "$sha_url"

  echo "Verifying checksum..."
  (cd "$download_dir" && sha256sum -c "$sha_name")

  if [ -d "$base" ] && [ "$current_version" != "none" ]; then
    local backup_file="$updates_dir/jonline-${current_version}-backup-$(date +%Y%m%d%H%M%S).tar.bz2"
    echo "Backing up current install (v${current_version}) to $backup_file"
    tar -cjf "$backup_file" --exclude='./.updates' -C "$base" .
  fi

  mkdir -p "$base"
  tar -xjf "$download_dir/$asset_name" -C "$base"
  rm -rf "$download_dir"
  _jonline_delete_foreign_arch_binaries "$base"

  echo "Updated to v${latest_version}."
}

# `update` keeps a backup of the previous install (and downloaded tarballs
# can accumulate in $updates_dir) so rollback is possible -- this clears
# that out, which can add up to a few hundred MB per update.
cleanup_updates() {
  local updates_dir="@@JONLINE_PACKAGE_BASE_DIR@@/.updates"
  if [ -d "$updates_dir" ]; then
    local freed
    freed="$(du -sh "$updates_dir" 2>/dev/null | cut -f1)"
    rm -rf "$updates_dir"
    echo "Removed $updates_dir (freed ${freed:-some space})."
  else
    echo "Nothing to clean up."
  fi
}

uninstall() {
  local base="@@JONLINE_PACKAGE_BASE_DIR@@"
  if [ ! -e "$base" ]; then
    echo "Nothing installed at $base."
    return 0
  fi

  local confirm=""
  if ! read -r -p "This will permanently delete $base (including any update backups). Press y to confirm: " confirm; then
    echo
    echo "Aborted (no input)." >&2
    exit 1
  fi

  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted."
    return 0
  fi

  rm -rf "$base"
  echo "Removed $base."
}

cmd="${1:-help}"
if [ $# -gt 0 ]; then
  shift
fi

case "$cmd" in
  help|-h|--help)
    jonline_help
    ;;
  server|version|environment|edit_environment|local_db_create|local_db_drop|local_db_reset|local_db_connect|local_minio_start|local_minio_create|local_minio_delete|local_instances_stop|delete_expired_tokens|delete_unowned_media|generate_preview_images|set_permission|delete_preview_images|disable_cdn_grpc|to_db_id|to_proto_id|grpcurl|install|show_latest|update|cleanup_updates|uninstall)
    "$cmd" "$@"
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    echo >&2
    jonline_help >&2
    exit 1
    ;;
esac
