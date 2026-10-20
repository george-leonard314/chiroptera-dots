#!/usr/bin/env bash
# One-time Spicetify setup for the Chiroptera theme. Run after installing
# spotify-launcher + spicetify-cli and opening Spotify once (so it is downloaded
# and its prefs file exists). Re-run after Spotify updates itself.
set -e
spotify_dir="$HOME/.local/share/spotify-launcher/install/usr/share/spotify"
[ -d "$spotify_dir" ] || { echo "Spotify not found at $spotify_dir; open Spotify once first."; exit 1; }
spicetify -q config spotify_path "$spotify_dir" prefs_path "$HOME/.config/spotify/prefs"
bash "$(dirname "$(readlink -f "$0")")/spicetify-apply.sh"
spicetify -q config current_theme Chiroptera color_scheme chiroptera \
  inject_css 1 replace_colors 1 overwrite_assets 0 inject_theme_js 0 \
  extensions chiroptera-live.js
spicetify -q backup apply 2>/dev/null || spicetify -q apply
echo "Spotify is themed by Chiroptera."
