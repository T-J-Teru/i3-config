<!--
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
-->

# i3-config

Personal configuration and setup notes for reproducing my machine environment,
starting with the **i3 window manager** on Fedora Workstation.

## Layout

```
.
├── README.md          # this file
├── i3-setup.md        # full narrative: what was done, why, and a change log
├── install.sh         # idempotent installer: packages + symlinks
├── dotfiles/
│   ├── i3/config      -> ~/.config/i3/config
│   └── rofi/          -> ~/.config/rofi/
└── bin/               -> ~/bin/   (i3 helper scripts; source of truth)
```

The repo holds the **real files**; the home directory holds **symlinks** pointing back
into it. Edit files here (not the symlinks).

## Fresh machine

```bash
git clone git@github.com:T-J-Teru/i3-config.git   # clone it wherever you like
cd i3-config
./install.sh            # installs packages (sudo) and creates symlinks
# log out, then choose the "i3" session at the gdm login screen
```

Re-running `install.sh` is safe; use `./install.sh --links` to (re)create symlinks
without touching packages.

See **[i3-setup.md](i3-setup.md)** for the detailed reasoning behind each choice.
