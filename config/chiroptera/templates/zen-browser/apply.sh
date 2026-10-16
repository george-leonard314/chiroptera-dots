#!/usr/bin/env bash
# Point every Zen Browser profile at the palette CSS Chiroptera Shell renders
# into ~/.cache/chiroptera/zen-browser/, and let Zen load userChrome.css and
# userContent.css at all. Runs as the post_hook of both zen-browser templates in
# config.toml; each run is idempotent, and it does nothing without Zen.
set -euo pipefail

palette_dir="${XDG_CACHE_HOME:-$HOME/.cache}/chiroptera/zen-browser"

# Replace $1 with $2 only when they differ, so Zen's file watchers stay quiet.
replace_if_changed() {
  if cmp -s "$1" "$2"; then
    rm -f "$2"
  else
    cat "$2" >"$1"
    rm -f "$2"
  fi
}

# Put `@import "<palette file>";` first in $1 (an @import must precede every
# other rule) and drop any older import of a zen-browser palette file named $2,
# wherever that one was rendered.
import_first() {
  local sheet=$1 name=$2 tmp
  tmp=$(mktemp "$sheet.XXXXXX")
  printf '@import "%s/%s";\n' "$palette_dir" "$name" >"$tmp"
  grep -v -F "zen-browser/$name" "$sheet" >>"$tmp" || true
  replace_if_changed "$sheet" "$tmp"
}

# user.js: Zen reads chrome/*.css only with this pref set.
enable_stylesheets() {
  local userjs=$1 tmp
  tmp=$(mktemp "$userjs.XXXXXX")
  grep -v -F 'toolkit.legacyUserProfileCustomizations.stylesheets' "$userjs" >"$tmp" || true
  printf '%s\n' 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >>"$tmp"
  replace_if_changed "$userjs" "$tmp"
}

roots=()
for dir in "${XDG_CONFIG_HOME:-$HOME/.config}/zen" "$HOME/.zen"; do
  [[ -d $dir ]] && roots+=("$dir")
done
((${#roots[@]} > 0)) || exit 0

# A profile is a directory directly under a root that holds prefs.js.
while IFS= read -r -d '' prefs; do
  profile=$(dirname "$prefs")
  mkdir -p "$profile/chrome"
  touch "$profile/chrome/userChrome.css" "$profile/chrome/userContent.css" "$profile/user.js"
  import_first "$profile/chrome/userChrome.css" zen-userChrome.css
  import_first "$profile/chrome/userContent.css" zen-userContent.css
  enable_stylesheets "$profile/user.js"
done < <(find "${roots[@]}" -mindepth 2 -maxdepth 2 -type f -name prefs.js -print0)
