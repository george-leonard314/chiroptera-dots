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
| `config/chiroptera` | shell config, palette templates for the terminal and the fastfetch logo |
| `config/fish` | shell config, the `faah` error sound and red border flash |
| `config/foot`, `config/btop`, `config/fastfetch`, `config/starship.toml` | terminal and tool configs, coloured by the shell's templates |
| `branding` | logo marks and the default wallpaper |
| `config/miscellaneous` | one-off helpers kept in `~/.config/miscellaneous`, such as the Fontys eduroam installer |
| `bin` | `chiroptera-super-tap` (tap Super for the launcher), `chiroptera-toggle` (special-workspace apps) |

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
