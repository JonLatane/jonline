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

Relies on Postgres's createdb/dropdb/psql for its local database, and on
docker for its local minio (S3-compatible storage). Edit ~/.jonline (created
on first run) to point DATABASE_URL/MINIO_* at different instances instead.

Quick start:
  jonline local_db_create && jonline local_minio_create && jonline server

Commands:
  server                 Run the Jonline server (jonline-server-<arch>)
  version                Print the Jonline server version (jonline-server-<arch> --version)

  environment            Print the current config (cat ~/.jonline)
  edit_environment       Edit the config in $EDITOR (falls back to vi)

  local_db_create        Create the local Postgres database (createdb jonline_dev)
  local_db_drop          Drop the local Postgres database (dropdb jonline_dev)
  local_db_reset         Stop local instances, then drop and recreate the local database
  local_db_connect       Connect to the local database with psql ($DATABASE_URL)

  local_minio_start      Start the existing local minio docker container
  local_minio_create     Start local minio, creating its docker container first if needed
  local_minio_delete     Stop and remove the local minio docker container
  local_instances_stop   Stop any running jonline-server processes

  install                Move this jonline folder to its canonical location
                          (@@JONLINE_PACKAGE_BASE_DIR@@), required once before `update` works
  show_latest            Print the latest Jonline release version available on GitHub
  update                 Download the latest release and install it, backing up the
                          current install first (requires `gh` and `jq`; requires `install` first)
  cleanup_updates        Delete backups/downloads accumulated by `update`, freeing disk space
  uninstall              Delete @@JONLINE_PACKAGE_BASE_DIR@@ entirely, after confirming (press y)

  help                   Show this help text

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

server() {
  cd "$(_jonline_package_dir)" && exec "./jonline-server-$(_jonline_arch)" "$@"
}

version() {
  server --version
}

environment() {
  cat "$JONLINE_ENV"
}

edit_environment() {
  # Intentionally unquoted: $EDITOR may be multiple words (e.g. "code --wait").
  ${EDITOR:-vi} "$JONLINE_ENV"
}

# Requires `gh` (GitHub CLI) and `jq`. Both just need to be installed --
# reading public release metadata doesn't require `gh auth login`.
show_latest() {
  gh api "repos/${JONLINE_RELEASES_REPO}/releases/latest" | jq -r '.tag_name'
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

  local latest_tag
  latest_tag="$(show_latest)"
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
  gh release download "$latest_tag" --repo "$JONLINE_RELEASES_REPO" --pattern "$asset_name" --pattern "$sha_name" --dir "$download_dir" --clobber

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
  server|version|environment|edit_environment|local_db_create|local_db_drop|local_db_reset|local_db_connect|local_minio_start|local_minio_create|local_minio_delete|local_instances_stop|install|show_latest|update|cleanup_updates|uninstall)
    "$cmd" "$@"
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    echo >&2
    jonline_help >&2
    exit 1
    ;;
esac
