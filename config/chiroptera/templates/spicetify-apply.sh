#!/usr/bin/env bash
# Pushes the rendered palette into Spotify. The theme files are copied next to the
# generated color.ini, then `spicetify refresh` rewrites colors.css/user.css inside
# Spotify (no restart); the chiroptera-live extension swaps them into open windows.
# A no-op until Spicetify is installed and set up (spicetify-setup.sh).
command -v spicetify >/dev/null || exit 0
src="$(dirname "$(readlink -f "$0")")"
dir="$(spicetify -c 2>/dev/null | xargs dirname 2>/dev/null)" || exit 0
[ -d "$dir" ] || exit 0
mkdir -p "$dir/Themes/Chiroptera" "$dir/Extensions"
cp -f "$src/spicetify-user.css" "$dir/Themes/Chiroptera/user.css"
cp -f "$src/spicetify-live.js" "$dir/Extensions/chiroptera-live.js"
spicetify -q refresh >/dev/null 2>&1 || true
