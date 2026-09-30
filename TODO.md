# TODO

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
