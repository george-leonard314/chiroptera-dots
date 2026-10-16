#!/usr/bin/env bash
# Fails if a caelestia reference survives, if the name of the project Chiroptera
# Shell was forked from appears anywhere, if a personal file is tracked, if
# config.toml depends on a plugin or template that does not ship here, or if a
# keybind points at a command that does not exist.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
status=0

# The shell's former name: in any file's content (text or binary) or name,
# tracked or untracked. Nothing here has to keep it, so only this script may
# spell it. The stem catches inflected forms in other languages too.
old_name=noctali
# Exception: the MIT notice of the vendored zen-browser template keeps its
# copyright line verbatim.
forked=$(git grep --untracked -n -i -e "$old_name" -- . ':!chiroptera/check-dots.sh' \
  ':!config/chiroptera/templates/zen-browser/LICENSE' || true)
forked_files=$(git ls-files --cached --others --exclude-standard | grep -i -e "$old_name" || true)
if [ -n "$forked$forked_files" ]; then
  echo "check-dots: the shell's former name appears:" >&2
  printf '%s\n' "$forked" "$forked_files" | grep -v '^$' >&2; status=1
fi

# Nothing is fetched for a new account: every plugin config.toml enables or puts
# in the bar, every community template it enables and every user template it
# renders must ship here (plugins under share/chiroptera/plugins, user
# templates under config/chiroptera).
if ! unshipped=$(python3 -I - config/chiroptera/config.toml share/chiroptera/plugins config <<'PY'
import pathlib, sys, tomllib

config_path, plugins_dir, config_dir = (pathlib.Path(a) for a in sys.argv[1:])
config = tomllib.loads(config_path.read_text())
shipped = set()
for manifest in plugins_dir.glob("*/plugin.toml"):
    shipped.add(tomllib.loads(manifest.read_text())["id"])
    if not (manifest.parent / "LICENSE").is_file():
        print(f"{manifest.parent}: vendored plugin without its LICENSE")

problems = []
for plugin in config.get("plugins", {}).get("enabled", []):
    if plugin not in shipped:
        problems.append(f"enabled plugin {plugin} does not ship in {plugins_dir}")
for name, widget in config.get("widget", {}).items():
    kind = widget.get("type", "")
    if ":" in kind and kind.split(":", 1)[0] not in shipped:
        problems.append(f"widget.{name} uses plugin {kind.split(':', 1)[0]}, which does not ship in {plugins_dir}")
templates = config.get("theme", {}).get("templates", {})
for template in templates.get("community_ids", []):
    problems.append(f"community template {template} is enabled, but none ships; use a user template")
for name, template in templates.get("user", {}).items():
    source = template.get("input_path", "")
    prefix = "~/.config/"
    if not source.startswith(prefix) or not (config_dir / source[len(prefix):]).is_file():
        problems.append(f"theme.templates.user.{name}: input {source} does not ship in {config_dir}")
print("\n".join(problems))
sys.exit(1 if problems else 0)
PY
); then
  echo "check-dots: config.toml depends on something that does not ship:" >&2
  echo "$unshipped" >&2; status=1
elif [ -n "$unshipped" ]; then
  echo "check-dots: $unshipped" >&2; status=1
fi

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
