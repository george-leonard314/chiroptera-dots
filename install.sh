#!/usr/bin/env bash
# Install the ChiropteraOS dotfiles into $XDG_CONFIG_HOME.
#
#   ./install.sh --link    symlink each entry to this checkout (development)
#   ./install.sh --copy    copy, skipping anything you have changed
#   ./install.sh --force   copy, overwriting
#   ./install.sh --diff    show what differs, change nothing
#
# Every replaced path is backed up as <path>.pre-dots-<timestamp> (never
# overwritten -- a colliding stamp gets a numeric suffix). A symlink into
# this checkout is never archived -- it holds no user content, git already
# versions its target. If a backup cannot be written, the run aborts and
# reports exactly which entries were already replaced before the failure.
set -euo pipefail
shopt -s nullglob
here=$(cd "$(dirname "$0")" && pwd)
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
data=${XDG_DATA_HOME:-$HOME/.local/share}
mode=${1:---copy}

entries=(hypr chiroptera fish foot btop fastfetch starship.toml uwsm)

# Run either from a git checkout or as the installed /usr/bin/chiroptera-dots.
if [ -d "$here/config" ]; then
  src_config="$here/config"
  src_branding="$here/branding"
  src_wallpapers="$here/branding/wallpapers"
  src_bin="$here/bin"
else
  src_config="/usr/share/chiroptera/dots"
  src_branding="/usr/share/chiroptera/branding"
  src_wallpapers="/usr/share/backgrounds/chiroptera"
  src_bin=""            # the package already installed these to /usr/bin
fi

# Destinations already replaced or linked in this run, so an abort can report
# real progress instead of implying nothing happened.
replaced=()

abort() {
  echo "install.sh: $1" >&2
  if [ "${#replaced[@]}" -gt 0 ]; then
    echo "install.sh: aborting. ${#replaced[@]} entr(y|ies) were already replaced in this run:" >&2
    printf '  %s\n' "${replaced[@]}" >&2
    echo "install.sh: the rest were not reached. Restore any of the above from its newest <path>.pre-dots-* backup." >&2
  else
    echo "install.sh: aborting. Nothing was replaced." >&2
  fi
  exit 1
}

backup() {
  local target=$1 resolved stamp dest n
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
  # Two runs in the same second still get distinct files: disambiguate on
  # collision rather than clobbering the earlier run's backup.
  stamp=$(date +%Y%m%d-%H%M%S)
  dest="$target.pre-dots-$stamp"
  n=1
  while [ -e "$dest" ] || [ -L "$dest" ]; do
    dest="$target.pre-dots-$stamp.$n"
    n=$((n + 1))
  done
  if ! cp -a "$target" "$dest"; then
    abort "could not back up $target"
  fi
  echo "backed up $target -> $dest"
}

case "$mode" in
  --diff)
    for e in "${entries[@]}"; do
      diff -rq "$src_config/$e" "$cfg/$e" 2>&1 | sed "s|$src_config/||;s|$cfg/||" || true
    done
    exit 0 ;;
  --link)
    if [ "$src_config" != "$here/config" ]; then
      echo "install.sh: --link needs a git checkout to link into; this is an installed copy with no source tree to link to. Use --copy or --force instead." >&2
      exit 2
    fi
    ;;
  --copy|--force) ;;
  *) echo "usage: $0 [--link|--copy|--force|--diff]" >&2; exit 2 ;;
esac

mkdir -p "$cfg" "$data/chiroptera" "$HOME/.local/bin" "$HOME/Pictures/Wallpapers"

for e in "${entries[@]}"; do
  src="$src_config/$e"; dst="$cfg/$e"
  [ -e "$src" ] || continue
  if [ "$mode" = "--link" ]; then
    backup "$dst"; rm -rf "$dst"; ln -s "$src" "$dst"; replaced+=("$dst"); echo "linked  $dst"
  elif [ -e "$dst" ] && [ "$mode" != "--force" ] && ! diff -rq "$src" "$dst" >/dev/null 2>&1; then
    echo "skipped $dst (differs; --force to overwrite)"
  else
    backup "$dst"; rm -rf "$dst"; cp -a "$src" "$dst"; replaced+=("$dst"); echo "copied  $dst"
  fi
done

# Branding and helper scripts are shared regardless of mode.
mkdir -p "$data/chiroptera/branding"
if [ -d "$src_branding" ]; then
  svgs=("$src_branding"/*.svg)
  if [ "${#svgs[@]}" -gt 0 ]; then
    cp -a "${svgs[@]}" "$data/chiroptera/branding/"
  else
    echo "no branding SVGs found in $src_branding" >&2
  fi
else
  echo "no branding directory found at $src_branding" >&2
fi

if [ -d "$src_wallpapers" ]; then
  cp -a "$src_wallpapers"/. "$HOME/Pictures/Wallpapers/"
else
  echo "no wallpapers found in $src_wallpapers" >&2
fi

if [ -n "$src_bin" ]; then
  bins=("$src_bin"/*)
  if [ "${#bins[@]}" -gt 0 ]; then
    install -m755 "${bins[@]}" "$HOME/.local/bin/"
  else
    echo "no helper scripts found in $src_bin" >&2
  fi
else
  echo "helper scripts come from the package (already in /usr/bin); skipping"
fi
echo "installed branding, wallpapers and helper scripts"

echo
echo "Done. Reload with:  hyprctl reload && chiroptera msg config-reload"
