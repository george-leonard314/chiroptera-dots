# TODO

## Ship the community templates the laptop uses

The laptop themes Steam, Claude Code, GIMP, Prism Launcher, hyprtoolkit, bat and fzf
through community templates the shell once downloaded into
`~/.local/state/chiroptera/community-templates`. A new account has none (the online catalog
is gone), so `config.toml` keeps community templates off. Vendor the ones worth keeping into
`config/chiroptera/templates/` as user templates, the way zen-browser was, under Chiroptera
names. fzf then needs `config/fish/conf.d/fzf-theme.fish` again (the laptop's copy reads the
old template's output file) pointed at the new output path.

## Hyprland: ship the Lua config

Hyprland 0.56 deprecated the `.conf` format and 0.57 removes it. On 2026-10-14 the laptop's
`~/.config/hypr` was ported to Lua (`hyprland.lua` plus `hyprland/*.lua` and `variables.lua`),
with the `.conf` files kept as a fallback. Hyprland loads `hyprland.lua` when it exists.
`config/hypr` in this repo still ships only `.conf`.

**When:** once Hyprland 0.57 is installed and the laptop has run on the Lua config without
problems. Until then the repo stays on `.conf`.

Then:

- Copy the Lua files from `~/.config/hypr` into `config/hypr` and drop the `.conf` files.
  Diff first: the live `animations`, `group`, `keybinds` and `variables` had already drifted
  from the repo before the port.
- `install.sh` writes a stub `chiroptera.conf` for the theme template. The Lua config needs a
  stub `chiroptera.lua` returning `{ apply_theme = function() end }` instead, or
  `require("chiroptera")` fails and stops the whole config. Once `hyprland.lua` exists, the
  template renders `chiroptera.lua` (`assets/templates/hyprland/apply.sh` in chiroptera-shell).
- `monitors.lua` (nwg-displays) and `hyprland/user.lua` are per machine. The repo should not
  ship them, so `hyprland.lua` should load them with `pcall(require, ...)`.
- Check with `Hyprland --verify-config` on a fresh account. It strictly rejects unknown
  fields and arguments.

## Elecwhat: live recolor and transparency

Elecwhat (WhatsApp Web) is themed from the wallpaper palette through
`config/chiroptera/templates/elecwhat.css`, rendered to `~/.config/elecwhat/chiroptera.css`
and loaded by the `css` entry in `~/.config/elecwhat/config.json`. Two gaps remain:

- **No live recolor.** Elecwhat inserts the CSS once per page load
  (`webContents.insertCSS` in `src/main.mjs`), so a new wallpaper shows after a restart
  or page reload. Fix: patch Elecwhat to watch the file and re-insert the CSS (or
  reuse the file-watching approach in `chiroptera-zen.cfg`).
- **No transparency.** The `BrowserWindow` is not created with `transparent: true` and
  there is no config option for it, so the background cannot be made see-through like
  Equicord (80% surfaces). Fix: patch Elecwhat to add a `transparent` config key, then make
  the template's surfaces translucent.

Elecwhat is the Arch package `elecwhat` (`/usr/lib/elecwhat/app.asar`, Electron 40), so a
patch has to be reapplied after updates: ship a patched fork package or a pacman hook.

Also unverified: the WhatsApp Web CSS variable names in `elecwhat.css` were written from
memory, not inspected on the live page. Check them with `"open-dev-tools": true`.

Not shipped yet: the `css` entry in `~/.config/elecwhat/config.json` that loads the
rendered file is set by hand on mainLaptop only. A fresh account renders
`chiroptera.css` but Elecwhat never loads it until that entry exists.
