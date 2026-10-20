#!/usr/bin/env python3
"""Copy the rendered Chiroptera KMG theme into every KMG workspace.

KMG reads themes from <workspace>/conf/appearance/themes/, one copy per
workspace, and ~/.config/kmg/workspace.json lists the workspaces. The copy is
rewritten in place, not replaced by rename: KMG's theme watcher only reacts to
writes, and a write to the theme in use recolors open windows live.
A workspace without the chiroptera theme gets it, with its theme.json.
"""
import json, os

src = os.path.expanduser("~/.cache/chiroptera/kmg/theme.css")
workspaces = os.path.expanduser("~/.config/kmg/workspace.json")
theme_json = {
    "name": "chiroptera",
    "author": "George (ChiropteraOS)",
    "url": "https://github.com/george-leonard314/ChiropteraOS",
    "version": "0.2.0",
    "displayName": {"default": "Chiroptera"},
    "description": {"default": "Backgrounds from the wallpaper, one accent color that follows the folder color of the open document. Port of the Obsidian Chiroptera Theme."},
    "frontends": ["all"],
    "modes": ["dark"],
}

if not os.path.exists(src) or not os.path.exists(workspaces):
    raise SystemExit(0)
css = open(src).read()
for ws in json.load(open(workspaces)):
    conf = os.path.join(ws, "conf")
    if not os.path.isdir(conf):
        continue
    theme = os.path.join(conf, "appearance", "themes", "chiroptera")
    os.makedirs(theme, exist_ok=True)
    meta = os.path.join(theme, "theme.json")
    if not os.path.exists(meta):
        with open(meta, "w") as f:
            json.dump(theme_json, f, indent=2); f.write("\n")
    path = os.path.join(theme, "theme.css")
    if os.path.exists(path) and open(path).read() == css:
        continue
    with open(path, "w") as f:
        f.write(css)
