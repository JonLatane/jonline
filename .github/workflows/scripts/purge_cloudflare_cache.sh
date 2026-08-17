#!/usr/bin/env bash
# Purges Cloudflare's edge cache for a Jonline web deployment -- but only the
# web/Elm/Tamagui/Flutter static assets actually baked into this build, never
# anything under /media/ (see backend/src/web/media.rs: media is cached for
# 12h and deliberately meant to survive deploys).
#
# Cloudflare's Purge Cache API only supports "purge everything" or "purge by
# exact URL" on our plan tier -- prefix/host/tag purging needs an Enterprise
# plan -- so this enumerates every real asset file from the build output
# directories and purges those URLs explicitly instead.
#
# Usage:   purge_cloudflare_cache.sh <domain>
# Env:     CLOUDFLARE_ZONE, CLOUDFLARE_TOKEN (required)
# Must be run from the repo root, after restoring the elm/tamagui/flutter
# build caches (see server_ci_cd.yml's deploy_* jobs).
set -euo pipefail

domain="${1:?usage: purge_cloudflare_cache.sh <domain>}"
: "${CLOUDFLARE_ZONE:?CLOUDFLARE_ZONE must be set}"
: "${CLOUDFLARE_TOKEN:?CLOUDFLARE_TOKEN must be set}"

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

urls=()

# Maps a build-output file to the clean URL it's actually served at:
#   index.html -> <prefix>/         foo.html -> <prefix>/foo
#   anything else (js/css/images/etc.) -> <prefix>/<relative path>
#
# Next's static export also emits dynamic-route fallback templates like
# "[username].html" or "g/[shortname]/p/[postId].html" -- Rocket reads those
# off disk by their literal filename to render arbitrary usernames/posts/etc.
# (see spa_file_or_username_or_custom_tab.rs), they're never themselves
# requested at that literal bracketed URL, so `*.html` files containing "["
# are skipped entirely. Their JS chunk counterparts (e.g.
# "_next/static/chunks/pages/[username]-<hash>.js") *are* real asset URLs a
# client fetches (with "[]" percent-encoded), so those are kept and encoded.
add_static_dir() {
  local dir="$1" prefix="$2"
  [ -d "$dir" ] || return 0
  while IFS= read -r -d '' file; do
    local rel="${file#"$dir"/}"
    case "$rel" in
    index.html) urls+=("https://${domain}${prefix}/") ;;
    *\[*.html) continue ;;
    *.html) urls+=("https://${domain}${prefix}/${rel%.html}") ;;
    *)
      local encoded="${rel//[/%5B}"
      encoded="${encoded//]/%5D}"
      urls+=("https://${domain}${prefix}/${encoded}")
      ;;
    esac
  done < <(find "$dir" -type f -print0)
}

# Elm SPA: served at /elm/<file>, home page at /elm (elm_web.rs).
add_static_dir frontends/elm-spa/public /elm
urls+=("https://${domain}/elm")

# Tamagui/Next: two parallel static exports -- "out" has no basePath baked
# in (served at bare "/"), "out-tamagui" has "/tamagui" baked in (served
# under that prefix) -- see spa_file_or_username_or_custom_tab.rs.
add_static_dir frontends/tamagui/apps/next/out ""
add_static_dir frontends/tamagui/apps/next/out-tamagui /tamagui
urls+=("https://${domain}/tamagui")

# Flutter web build: served at /flutter/<file>, home page at /flutter
# (flutter_web.rs).
add_static_dir frontends/flutter/build/web /flutter
urls+=("https://${domain}/flutter")

# Bare "/" resolves to whichever app the server's WebUserInterface is
# configured for -- always worth refreshing regardless of which build
# produced it.
urls+=("https://${domain}/")

# Server-rendered SEO pages, cached up to an hour (robots_sitemap.rs).
urls+=("https://${domain}/robots.txt" "https://${domain}/sitemap.xml")

# (avoiding `mapfile`/`readarray` here -- not available on bash 3.2, e.g. macOS's default)
urls=($(printf '%s\n' "${urls[@]}" | sort -u))

echo "Purging ${#urls[@]} Cloudflare cache entries for ${domain} (excluding /media/)..."

batch_size=30
for ((i = 0; i < ${#urls[@]}; i += batch_size)); do
  batch=("${urls[@]:i:batch_size}")
  json_files=$(printf '%s\n' "${batch[@]}" | jq -R . | jq -s '{files: .}')
  curl -sS --fail -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE}/purge_cache" \
    -H "Authorization: Bearer ${CLOUDFLARE_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "$json_files"
  echo
done
