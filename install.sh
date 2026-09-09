#!/usr/bin/env bash
# Install the ChiropteraOS dotfiles into $XDG_CONFIG_HOME.
#
#   ./install.sh --link    symlink each entry to this checkout (development)
#   ./install.sh --copy    copy, skipping anything you have changed
#   ./install.sh --force   copy, overwriting
#   ./install.sh --diff    show what differs, change nothing
#
# A replaced path is backed up once as <path>.pre-dots.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
data=${XDG_DATA_HOME:-$HOME/.local/share}
mode=${1:---copy}

entries=(hypr chiroptera fish foot btop fastfetch starship.toml uwsm)

backup() { [ -e "$1" ] && [ ! -e "$1.pre-dots" ] && cp -a "$1" "$1.pre-dots" || true; }

case "$mode" in
  --diff)
    for e in "${entries[@]}"; do
      diff -rq "$here/config/$e" "$cfg/$e" 2>&1 | sed "s|$here/config/||;s|$cfg/||" || true
    done
    exit 0 ;;
  --link|--copy|--force) ;;
  *) echo "usage: $0 [--link|--copy|--force|--diff]" >&2; exit 2 ;;
esac

mkdir -p "$cfg" "$data/chiroptera" "$HOME/.local/bin" "$HOME/Pictures/Wallpapers"

for e in "${entries[@]}"; do
  src="$here/config/$e"; dst="$cfg/$e"
  [ -e "$src" ] || continue
  if [ "$mode" = "--link" ]; then
    backup "$dst"; rm -rf "$dst"; ln -s "$src" "$dst"; echo "linked  $dst"
  elif [ -e "$dst" ] && [ "$mode" != "--force" ] && ! diff -rq "$src" "$dst" >/dev/null 2>&1; then
    echo "skipped $dst (differs; --force to overwrite)"
  else
    backup "$dst"; rm -rf "$dst"; cp -a "$src" "$dst"; echo "copied  $dst"
  fi
done

# Branding and helper scripts are shared regardless of mode.
mkdir -p "$data/chiroptera/branding"
cp -a "$here"/branding/*.svg "$data/chiroptera/branding/"
cp -a "$here"/branding/wallpapers/. "$HOME/Pictures/Wallpapers/"
install -m755 "$here"/bin/* "$HOME/.local/bin/"
echo "installed branding, wallpapers and helper scripts"

echo
echo "Done. Reload with:  hyprctl reload && chiroptera msg config-reload"
