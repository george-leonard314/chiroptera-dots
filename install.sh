#!/usr/bin/env bash
# Install the ChiropteraOS dotfiles into $XDG_CONFIG_HOME, and the shell
# plugins they enable into $XDG_DATA_HOME/chiroptera/plugins.
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

entries=(hypr chiroptera fish foot btop fastfetch starship.toml uwsm pacseek fontconfig miscellaneous gtk-3.0 gtk-4.0 xfce4)

# Run either from a git checkout or as the installed /usr/bin/chiroptera-dots.
if [ -d "$here/config" ]; then
  src_config="$here/config"
  src_branding="$here/branding"
  src_wallpapers="$here/branding/wallpapers"
  src_bin="$here/bin"
  src_plugins="$here/share/chiroptera/plugins"
else
  src_config="/usr/share/chiroptera/dots"
  src_branding="/usr/share/chiroptera/branding"
  src_wallpapers="/usr/share/backgrounds/chiroptera"
  src_bin=""            # the package already installed these to /usr/bin
  src_plugins="/usr/share/chiroptera/plugins"
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

# backup PATH [DIR]: archive PATH next to itself, or into DIR when given.
backup() {
  local target=$1 into=${2:-} resolved stamp dest n
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
  if [ -n "$into" ]; then
    mkdir -p "$into" || abort "could not create $into"
    dest="$into/${target##*/}.pre-dots-$stamp"
  fi
  n=1
  while [ -e "$dest" ] || [ -L "$dest" ]; do
    dest="${dest%.pre-dots-*}.pre-dots-$stamp.$n"
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
    for p in "$src_plugins"/*/; do
      p=${p%/}
      diff -rq "$p" "$data/chiroptera/plugins/${p##*/}" 2>&1 | sed "s|$src_plugins/|plugins/|;s|$data/chiroptera/||" || true
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

# place SRC DST [BACKUP_DIR]: link, copy or skip one entry, per the mode.
place() {
  local src=$1 dst=$2 into=${3:-}
  [ -e "$src" ] || return 0
  if [ "$mode" = "--link" ]; then
    backup "$dst" "$into"; rm -rf "$dst"; ln -s "$src" "$dst"; replaced+=("$dst"); echo "linked  $dst"
  elif [ -e "$dst" ] && [ "$mode" != "--force" ] && ! diff -rq "$src" "$dst" >/dev/null 2>&1; then
    echo "skipped $dst (differs; --force to overwrite)"
  else
    backup "$dst" "$into"; rm -rf "$dst"; cp -a "$src" "$dst"; replaced+=("$dst"); echo "copied  $dst"
  fi
}

for e in "${entries[@]}"; do
  place "$src_config/$e" "$cfg/$e"
done

# Plugins config.toml enables, into the shell's local plugin source. Only these
# plugins' own folders are touched; other plugins there are left alone. Their
# backups go beside that folder, not into it: the shell would load a backed-up
# plugin.toml as a second copy of the plugin.
mkdir -p "$data/chiroptera/plugins"
for p in "$src_plugins"/*/; do
  p=${p%/}
  place "$p" "$data/chiroptera/plugins/${p##*/}" "$data/chiroptera/plugin-backups"
done

# hyprland.conf sources the Hyprland theme template's output, which the repo doesn't
# track; give Hyprland an empty stand-in until the shell renders the palette.
[ -e "$cfg/hypr/chiroptera.conf" ] \
  || printf '# Rendered by the Chiroptera Hyprland theme template.\n' > "$cfg/hypr/chiroptera.conf"

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
