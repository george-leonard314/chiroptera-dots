#!/usr/bin/env bash
# Install the ChiropteraOS dotfiles into $XDG_CONFIG_HOME.
#
#   ./install.sh --link    symlink each entry to this checkout (development)
#   ./install.sh --copy    copy, skipping anything you have changed
#   ./install.sh --force   copy, overwriting
#   ./install.sh --diff    show what differs, change nothing
#
# Every replaced path is backed up as <path>.pre-dots-<timestamp> (one new
# backup per run, never overwritten). A symlink into this checkout is never
# archived -- it holds no user content, git already versions its target. If a
# backup cannot be written, the run aborts before anything is replaced.
set -euo pipefail
shopt -s nullglob
here=$(cd "$(dirname "$0")" && pwd)
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
data=${XDG_DATA_HOME:-$HOME/.local/share}
mode=${1:---copy}

entries=(hypr chiroptera fish foot btop fastfetch starship.toml uwsm)

backup() {
  local target=$1 resolved stamp dest
  # Nothing there (note: -e is false for a dangling symlink, so test -L too).
  [ -e "$target" ] || [ -L "$target" ] || return 0

  # A symlink into this checkout holds no user content: its target is the repo,
  # which git already versions. Archiving it would create a useless self-reference.
  if [ -L "$target" ]; then
    resolved=$(readlink -f "$target" 2>/dev/null || true)
    case "$resolved" in
      "$here"|"$here"/*) return 0 ;;
    esac
  fi

  # Timestamped, so a later edit is never silently overwritten by a second run.
  stamp=$(date +%Y%m%d-%H%M%S)
  dest="$target.pre-dots-$stamp"
  if ! cp -a "$target" "$dest"; then
    echo "install.sh: could not back up $target -- aborting before anything is replaced" >&2
    exit 1
  fi
  echo "backed up $target -> $dest"
}

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
svgs=("$here"/branding/*.svg)
if [ "${#svgs[@]}" -gt 0 ]; then
  cp -a "${svgs[@]}" "$data/chiroptera/branding/"
else
  echo "no branding SVGs found in $here/branding" >&2
fi
cp -a "$here"/branding/wallpapers/. "$HOME/Pictures/Wallpapers/"
bins=("$here"/bin/*)
if [ "${#bins[@]}" -gt 0 ]; then
  install -m755 "${bins[@]}" "$HOME/.local/bin/"
else
  echo "no helper scripts found in $here/bin" >&2
fi
echo "installed branding, wallpapers and helper scripts"

echo
echo "Done. Reload with:  hyprctl reload && chiroptera msg config-reload"
