# Hidden launcher entries

Desktop entries that dependencies install and nobody wants in the launcher.
Each file shadows the system one by having the same name earlier in
`XDG_DATA_DIRS`, and sets `NoDisplay=true`; the programs still run, and the
keybinds that use them (Ctrl+Alt+Escape opens qps) are unaffected.

Delete a file here to get its entry back.

| Hidden | Comes from | Still reachable through |
|---|---|---|
| qt5ct, qt6ct | chiroptera-meta, themes Qt apps | `qt6ct` in a terminal |
| uuctl | uwsm | `uuctl` in a terminal |
| lstopo | hwloc, pulled in by file-roller | `lstopo` in a terminal |
| bssh, bvnc | avahi, pulled in by PipeWire and printing | `bssh` / `bvnc` |
| thunar-bulk-rename | thunar | Thunar's right-click menu |
| qps | chiroptera-meta | Ctrl+Alt+Escape |
