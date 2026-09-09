# chiroptera-dots

The dotfiles of ChiropteraOS: Hyprland, Chiroptera Shell, fish, foot, fastfetch,
btop and starship, as used on the author's machine.

## Install

```sh
git clone https://github.com/george-leonard314/chiroptera-dots
cd chiroptera-dots
./install.sh --copy      # or --link to develop against this checkout
hyprctl reload && chiroptera msg config-reload
```

`--diff` shows what would change; `--force` overwrites. Anything replaced is
backed up once as `<path>.pre-dots`.

## What is here

| Path | Purpose |
|---|---|
| `config/hypr` | Hyprland: keybinds via Chiroptera IPC, window rules, autostart |
| `config/chiroptera` | shell config, palette templates for the terminal and the fastfetch logo |
| `config/fish` | shell config, the `faah` error sound and red border flash |
| `config/foot`, `config/btop`, `config/fastfetch`, `config/starship.toml` | terminal and tool configs, coloured by the shell's templates |
| `branding` | logo marks and the default wallpaper |
| `bin` | `chiroptera-super-tap` (tap Super for the launcher), `chiroptera-toggle` (special-workspace apps) |

## Machine-local settings

Put anything specific to one machine in `~/.config/hypr/hyprland/user.conf`,
which is sourced last. Monitor layout lives in `~/.config/hypr/monitors.conf`
and is deliberately not tracked.
