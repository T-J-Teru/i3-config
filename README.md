# Machine-Setup

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
git clone <this-repo> ~/Documents/Machine-Setup
cd ~/Documents/Machine-Setup
./install.sh            # installs packages (sudo) and creates symlinks
# log out, then choose the "i3" session at the gdm login screen
```

Re-running `install.sh` is safe; use `./install.sh --links` to (re)create symlinks
without touching packages.

See **[i3-setup.md](i3-setup.md)** for the detailed reasoning behind each choice.
