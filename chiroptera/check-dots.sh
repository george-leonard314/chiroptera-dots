#!/usr/bin/env bash
# Fails if a caelestia reference survives, if a personal file is tracked, or if a
# keybind points at a command that does not exist.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
status=0

leftovers=$(grep -rn -i 'caelestia' config branding bin 2>/dev/null | grep -v '<!-- keep -->' || true)
if [ -n "$leftovers" ]; then
  echo "check-dots: caelestia references remain:" >&2; echo "$leftovers" >&2; status=1
fi

personal=$(git ls-files | grep -E 'monitors\.(conf|lua)|fish_variables|secrets|\.bak$|\.pre-' || true)
if [ -n "$personal" ]; then
  echo "check-dots: personal or backup files are tracked:" >&2; echo "$personal" >&2; status=1
fi

generated=$(git ls-files | grep -E 'config/(foot|fastfetch|btop)/themes/|scheme/current\.conf' || true)
if [ -n "$generated" ]; then
  echo "check-dots: generated files are tracked:" >&2; echo "$generated" >&2; status=1
fi

# Every `chiroptera msg <cmd> ...` in config/ must be a real IPC command, and its
# arguments must be real panel ids / media actions / session actions / plugin ids
# (not just the subcommand — a valid subcommand with a typo'd argument is still dead).
if command -v chiroptera >/dev/null; then
  valid=$(chiroptera msg --help 2>&1 | grep -E '^\s{2}[a-z]' | awk '{print $1}')
  panel_ids=$'clipboard\ncontrol-center\nlauncher\npolkit\nsession\nsetup-wizard\ntray-drawer\nwallpaper'
  media_actions=$'next\nprevious\ntoggle\nplay\npause\nstop\nnext-player\nprevious-player'
  session_actions=$'lock\nsuspend\nlock-and-suspend\nlogout\nreboot\nshutdown'
  plugins=$(chiroptera msg plugins list 2>&1 | awk '{print $1}')

  invocations=$(grep -rohE 'chiroptera msg [^#]*' config 2>/dev/null | sed -E 's/[[:space:]]+$//' | sort -u)
  while IFS= read -r inv; do
    [ -z "$inv" ] && continue
    read -r _bin _msg cmd rest <<<"$inv"
    if ! grep -qx "$cmd" <<<"$valid"; then
      echo "check-dots: unknown IPC command '$cmd' in '$inv'" >&2; status=1; continue
    fi
    arg1="${rest%% *}"
    case "$cmd" in
      panel-toggle|panel-open|panel-close)
        grep -qx "$arg1" <<<"$panel_ids" || { echo "check-dots: unknown panel id '$arg1' in '$inv'" >&2; status=1; }
        ;;
      media)
        grep -qx "$arg1" <<<"$media_actions" || { echo "check-dots: unknown media action '$arg1' in '$inv'" >&2; status=1; }
        ;;
      session)
        grep -qx "$arg1" <<<"$session_actions" || { echo "check-dots: unknown session action '$arg1' in '$inv'" >&2; status=1; }
        ;;
      plugin)
        authorplugin="${arg1%%:*}"
        grep -qx "$authorplugin" <<<"$plugins" || { echo "check-dots: unknown plugin id '$authorplugin' in '$inv'" >&2; status=1; }
        ;;
    esac
  done <<<"$invocations"
fi

[ "$status" -eq 0 ] && echo "check-dots: ok"
exit "$status"
