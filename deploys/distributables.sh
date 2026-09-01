# Shared `deploy` subcommand implementation for the `jonline` launcher scripts shipped in the
# Homebrew and Linux packages (docs/homebrew_jonline.sh and docs/linux_jonline.sh). Both launchers
# bundle a full copy of `deploys/` (this file included -- see the "Assemble ... package layout"
# steps of .github/workflows/server_ci_cd.yml's create_homebrew_release/create_linux_release jobs)
# and source this file lazily, only when their `deploy`/`_jonline_deploy_targets` functions are
# actually invoked, since it only exists once installed -- not when a launcher is run standalone/
# uninstalled for local testing (see each launcher's own header comment).
#
# Each launcher resolves its own install-dependent deploys dir differently (Homebrew's fixed
# @@JONLINE_ETC@@/jonline/opt/deploys vs. Linux's runtime-resolved
# $(_jonline_package_dir)/opt/deploys), so that resolution stays in the launcher; this file just
# takes the resolved dir as an explicit argument. Not meant to be run standalone -- it's sourced
# into a launcher that's already running under `set -euo pipefail`.

# Usage: _jonline_deploys_run <deploys_dir> [make targets and/or VAR=value overrides...]
# Forwards args straight to `make -C <deploys_dir>`, so both targets (create_external_backend, ...)
# and VAR=value overrides (e.g. NAMESPACE=my_namespace, required by nearly every target -- see
# deploys/README.md) just work, same as running `make` by hand from that directory.
_jonline_deploys_run() {
  local deploys_dir="$1"
  shift
  command -v make >/dev/null 2>&1 || {
    echo "jonline deploy requires 'make' -- see $deploys_dir/README.md." >&2
    exit 1
  }
  make -C "$deploys_dir" "$@"
}

# Usage: _jonline_deploys_list_targets <deploys_dir>
# Prints deploys/Makefile's target names by asking `make` itself to parse the file and dump its
# internal database (`-qp`), rather than hand-rolling a regex over the Makefile text -- the same
# trick bash-completion's own `_make` completion function uses (including its "# Not a target:"
# annotation handling below, needed to exclude non-target database entries like .DEFAULT_GOAL).
# Used by each launcher's `completion` for deploy-target completion. NAMESPACE is required by the
# Makefile (see deploys/README.md) but irrelevant to just listing target names, so a placeholder
# is passed here to satisfy that check.
_jonline_deploys_list_targets() {
  local deploys_dir="$1"
  command -v make >/dev/null 2>&1 || return 0
  LC_ALL=C make -C "$deploys_dir" -qp NAMESPACE=_completion_placeholder_ 2>/dev/null \
    | awk -v RS= -F: '/(^|\n)# File/,/^# make/ { if ($1 !~ "^[#.\t]") { print $1 } }' \
    | tr ' ' '\n' \
    | sort -u
}
