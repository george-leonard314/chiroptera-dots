# Bundled shell plugins

The Chiroptera Shell plugins `config/chiroptera/config.toml` enables. The shell
fetches no online plugin catalog, so they ship here:

| Folder | Plugin id | Author | License |
| --- | --- | --- | --- |
| `arch-updater` | `yuuto/arch-updater` | yuuto | MIT |
| `obs-control` | `ayagmar/obs-control` | ayagmar | MIT |
| `w-engine` | `tadomika_ari/w-engine` | TadomiKa-Ari | MIT |

`install.sh` copies (or, with `--link`, links) each folder into
`~/.local/share/chiroptera/plugins/`, the shell's local plugin source, which
outranks every other source. The chiroptera-dots package installs them to
`/usr/share/chiroptera/plugins/` and, for new accounts, to
`/etc/skel/.local/share/chiroptera/plugins/`.

To add a plugin to the defaults, put its folder here with its LICENSE, enable
its id in `config.toml`, and run `chiroptera/check-dots.sh`: it fails when
`config.toml` enables a plugin or template that does not ship in this
repository. See CREDITS for what was changed in each copy.
