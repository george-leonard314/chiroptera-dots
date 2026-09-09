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

# Every `chiroptera msg <cmd>` in the keybinds must be a real IPC command.
if command -v chiroptera >/dev/null; then
  valid=$(chiroptera msg --help 2>&1 | grep -E '^\s{2}[a-z]' | awk '{print $1}')
  used=$(grep -ohE 'chiroptera msg [a-z-]+' config/hypr -r | awk '{print $3}' | sort -u)
  for cmd in $used; do
    grep -qx "$cmd" <<<"$valid" || { echo "check-dots: unknown IPC command '$cmd'" >&2; status=1; }
  done
fi

[ "$status" -eq 0 ] && echo "check-dots: ok"
exit "$status"
