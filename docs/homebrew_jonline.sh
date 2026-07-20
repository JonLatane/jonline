#!/bin/bash
#
# Source of truth for the `jonline` launcher script installed by Homebrew
# (JonLatane/homebrew-jonline) as `bin/jonline`.
#
# This file is spliced verbatim into Formula/jonline.rb's `install` method by
# the "Push Formula/jonline.rb to JonLatane/homebrew-jonline" step of the
# Server CI/CD workflow (create_homebrew_release job) in
# .github/workflows/server_ci_cd.yml -- don't hand-edit the generated
# Formula, edit this file instead.
#
# The one placeholder below, @@JONLINE_ETC@@, is replaced by that CI step
# with Ruby's `#{etc}` string interpolation, which Homebrew resolves to the
# formula's installed etc/ prefix (e.g. /opt/homebrew/etc) when the user runs
# `brew install`. That path isn't known until install time and can differ
# per machine, so it can't be baked in here as a real value -- but aside from
# that one substitution, this file is plain, valid, directly-runnable bash
# (e.g. `bash docs/homebrew_jonline.sh help` works locally; `server` is the
# only subcommand that needs the real substitution to find its install dir).
#
set -euo pipefail

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
  server                 Run the Jonline server (jonline-server)
  version                Print the Jonline server version (jonline-server --version)
  local_db_create        Create the local Postgres database (createdb jonline_dev)
  local_db_drop          Drop the local Postgres database (dropdb jonline_dev)
  local_db_reset         Stop local instances, then drop and recreate the local database
  local_db_connect       Connect to the local database with psql ($DATABASE_URL)
  local_minio_start      Start the existing local minio docker container
  local_minio_create     Start local minio, creating its docker container first if needed
  local_minio_delete     Stop and remove the local minio docker container
  local_instances_stop   Stop any running jonline-server processes
  help                   Show this help text
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
  killall jonline-server || true
}

server() {
  cd "@@JONLINE_ETC@@/jonline" && exec ./jonline-server "$@"
}

version() {
  server --version
}

cmd="${1:-help}"
if [ $# -gt 0 ]; then
  shift
fi

case "$cmd" in
  help|-h|--help)
    jonline_help
    ;;
  server|version|local_db_create|local_db_drop|local_db_reset|local_db_connect|local_minio_start|local_minio_create|local_minio_delete|local_instances_stop)
    "$cmd" "$@"
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    echo >&2
    jonline_help >&2
    exit 1
    ;;
esac
