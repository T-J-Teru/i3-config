# i3-config

i3 window manager environment for a Fedora workstation running X11 (ThinkPad T14s). Licensed GPLv3.

See **i3-setup.md** for the full narrative design document and changelog. That file is the authoritative reference for why things are set up the way they are.

## Repo layout

```
install.sh          # idempotent installer: packages + symlinks + system config
bin/                # ~/bin helper scripts (i3-exit, i3-wallpaper, etc.)
dotfiles/
  i3/config         # -> ~/.config/i3/config
  picom/picom.conf  # -> ~/.config/picom/picom.conf (compositor)
  polybar/          # -> ~/.config/polybar/ (status bar)
  deadd/            # -> ~/.config/deadd/ (notification daemon)
  rofi/             # -> ~/.config/rofi/ (launcher theme)
  autorandr/        # -> ~/.config/autorandr/ (monitor profile hooks)
  profile           # -> ~/.profile (SSH agent setup)
  gtk-3.0/          # -> ~/.config/gtk-3.0/ (dark theme for GTK3)
  modprobe.d/       # copied to /etc/modprobe.d/ (pcspkr blacklist)
  applications/     # -> ~/.local/share/applications/ (desktop entry overrides)
  xscreensaver/     # -> ~/.xscreensaver (lock/idle config)
i3-setup.md         # design document and changelog
```

## Conventions

- **install.sh** resolves its own directory (`REPO=...`) so it works from any cwd. Uses `set -euo pipefail`. Supports `--links` to skip dnf/sudo/system-config steps.
- **Symlinks are explicit** in `create_symlinks()` -- no stow. The `bin/` scripts are linked via a `for` loop.
- **GPL headers** go on `install.sh` and every `bin/` script. Do NOT add headers to config files (i3/config, picom.conf, polybar config, etc.) -- picom.conf is an exception that already has one.
- **Third-party files** get a provenance comment instead of a GPL header.
- **System-level config** (keyboard layout, timezone, pcspkr) is in install.sh and requires sudo. These are skipped with `--links`.
- **deadd** (notification daemon) is built from source, not packaged. The binary is installed to `~/bin` as a real file, not a symlink.
- **i3-setup.md** should be updated with a changelog entry when making significant changes.

## Key technical details

- **Terminal**: alacritty (`$mod+Return`). Sets `TERM=alacritty` which can break SSH to hosts without its terminfo.
- **Compositor (picom)**: GLX backend. Rounded corners and shadows are scoped to **floating windows + notifications only** using `I3_FLOATING_WINDOW` (a CARDINAL property i3 sets on floating windows). Match both `@` (client) and frame: `!(I3_FLOATING_WINDOW@ = 1 || I3_FLOATING_WINDOW = 1) && window_type != 'notification'`.
- **Screen lock**: xscreensaver. `i3-exit lock` uses `-lock` (on-demand); `i3-exit suspend/hibernate` uses `-suspend` (blanks+locks immediately, ignoring lock-timeout). Pointer is warped to the laptop panel first so the unlock dialog appears there.
- **Polkit**: `mate-polkit` (Fedora dropped `polkit-gnome`). Started from the i3 config. Required for virt-manager and other GUI privilege escalation.
- **Calculator scratchpad**: qalc in urxvt, kept in i3's scratchpad.
- **Monitor layout**: autorandr for automatic profile switching; arandr for manual setup.

## When editing

- If adding a new package, add it to `PACKAGES` in install.sh with a comment explaining what uses it and a cross-reference to i3-setup.md if applicable.
- If adding a new dotfile, add an explicit `link` call in `create_symlinks()`.
- If adding a new `bin/` script, the loop picks it up -- just add the GPL header and make it executable.
- Validate picom config changes with: `timeout 5 picom --config dotfiles/picom/picom.conf --diagnostics`
- Update i3-setup.md when making significant changes (add a changelog entry at the bottom).
