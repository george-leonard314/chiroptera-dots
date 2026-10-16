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
backed up as `<path>.pre-dots-<timestamp>` on every run; a failed backup
aborts before anything is touched.

## What is here

| Path | Purpose |
|---|---|
| `config/hypr` | Hyprland: keybinds via Chiroptera IPC, window rules, autostart |
| `config/chiroptera` | Chiroptera Shell `config.toml` and wallpaper-palette templates: terminal, fastfetch logo, VSCodium, Equicord, Elecwhat |
| `config/fish` | shell config, the `faah` error sound and red border flash |
| `config/foot`, `config/btop`, `config/fastfetch`, `config/starship.toml` | terminal and tool configs, coloured by the shell's templates |
| `config/gtk-3.0`, `config/gtk-4.0`, `config/fontconfig`, `config/xfce4` | GTK theme and fonts, Thunar |
| `config/uwsm`, `config/pacseek` | session environment, package search TUI |
| `config/miscellaneous` | one-off helpers kept in `~/.config/miscellaneous`, such as the Fontys eduroam installer |
| `branding` | bat logo marks and the default wallpapers |
| `bin` | `chiroptera-super-tap` (tap Super for the launcher), `chiroptera-toggle` (special-workspace apps), `chiroptera-apps`, `chiroptera-blackarch`, `chiroptera-browser` |
| `share/applications` | launcher entries hidden on purpose (see its README) |
| `packages` | the author's app lists for `chiroptera-apps` |
| `chiroptera/check-dots.sh` | fails on the shell's former name anywhere, a tracked personal file, a generated file, or a keybind pointing at a command that does not exist |

ChiropteraOS packages this repository as `chiroptera-dots`. The trees go to
`/usr/share/chiroptera/dots`, which the installed `chiroptera-dots` command (this
`install.sh`) copies from, and to `/etc/skel`, so new accounts start with them.

## eduroam (Fontys)

`config/miscellaneous/eduroam-fontys.py` is the eduroam CAT installer for Fontys
Hogescholen, patched for current NetworkManager. The stock script points the
profile at a rehashed CA directory (`802-1x.ca-path`); NetworkManager 1.58 and
later refuse that on per-user profiles, so activation fails with
`supplicant-config-failed`. The patched copy always uses a single CA bundle
(`802-1x.ca-cert`), with server certificate checking unchanged.

```sh
python3 ~/.config/miscellaneous/eduroam-fontys.py   # asks for username and password
nmcli --ask con up eduroam
```

It needs `python-dbus`. Other institutions: download their script from
https://cat.eduroam.org and apply the same change to `save_ca`.

## Machine-local settings

Put anything specific to one machine in `~/.config/hypr/hyprland/user.conf`,
which is sourced last. Monitor layout lives in `~/.config/hypr/monitors.conf`
and is deliberately not tracked.

## Apps

`packages/apps.txt` lists the author's apps beyond the desktop: Arch and
CachyOS repository packages and AUR packages. `packages/apps-blackarch.txt`
holds the ones that need the BlackArch repository. On a fresh ChiropteraOS,
after first boot:

```sh
chiroptera-apps
```

It installs everything through paru with `--needed`, so re-running it is
safe. The BlackArch list is skipped unless `[blackarch]` is configured.

## License

GPL-3.0. See `LICENSE` and `CREDITS`.
