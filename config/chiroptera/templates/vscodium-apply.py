#!/usr/bin/env python3
"""Merge the rendered Chiroptera palette into VSCodium's settings.json.

VSCodium re-applies workbench.colorCustomizations the moment settings.json is
saved, so a new wallpaper recolors every open window without a reload.
Only the two palette keys are touched; the rest of settings.json is preserved.
"""
import json, os, re, sys, tempfile

src = os.path.expanduser("~/.cache/chiroptera/vscodium/colors.json")
dirs = [os.path.expanduser(p) for p in ("~/.config/VSCodium/User", "~/.config/Code - OSS/User")]

def strip_jsonc(text):
    # Drop // and /* */ comments outside strings, then trailing commas.
    out, i, n, in_str = [], 0, len(text), False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if c == "\\": out.append(text[i + 1]); i += 1
            elif c == '"': in_str = False
        elif c == '"': in_str = True; out.append(c)
        elif text.startswith("//", i): i = text.find("\n", i); i = n if i < 0 else i - 1
        elif text.startswith("/*", i): i = text.find("*/", i) + 1
        else: out.append(c)
        i += 1
    return re.sub(r",(\s*[}\]])", r"\1", "".join(out))

palette = json.load(open(src))
for d in dirs:
    if not os.path.isdir(d): continue
    path = os.path.join(d, "settings.json")
    settings = {}
    if os.path.exists(path):
        raw = open(path).read()
        try: settings = json.loads(strip_jsonc(raw)) if raw.strip() else {}
        except ValueError:
            print(f"chiroptera-vscodium: {path} is not parseable, skipping", file=sys.stderr); continue
    if all(settings.get(k) == v for k, v in palette.items()): continue
    settings.update(palette)
    fd, tmp = tempfile.mkstemp(dir=d, suffix=".tmp")
    with os.fdopen(fd, "w") as f: json.dump(settings, f, indent=4); f.write("\n")
    os.replace(tmp, path)
