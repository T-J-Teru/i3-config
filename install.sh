#!/usr/bin/env bash
#
# install.sh -- set up this machine's i3 environment from the Machine-Setup repo.
#
# Idempotent: safe to re-run. It (1) installs the required packages and (2) creates
# symlinks from the home directory into this repo. Any pre-existing *real* file that
# would be overwritten is backed up to <file>.bak first.
#
# Usage:  ./install.sh            # packages + symlinks
#         ./install.sh --links    # symlinks only (skip dnf)
#
# See i3-setup.md for the full narrative and rationale.

set -euo pipefail

# Resolve the repo root (directory containing this script), regardless of cwd.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#-----------------------------------------------------------------------------#
# 1. Packages
#-----------------------------------------------------------------------------#

PACKAGES=(
  # Xorg server + startup glue -- i3 is X11 and Fedora ships Wayland-only by default.
  xorg-x11-server-Xorg xorg-x11-xinit

  # i3 window manager + screen saver/locker. (i3status kept as an i3bar fallback;
  # the active status bar is polybar, below.)
  i3 i3status xscreensaver

  # Status bar (replaces i3bar/i3status). See "Status bar (polybar)" in i3-setup.md.
  polybar

  # Compositor: translucency, drop shadows, frosted-glass blur, rounded corners
  # (most visibly the deadd notification cards). See "Compositor (picom)" in i3-setup.md.
  picom

  # Glyph icon font for the polybar status modules (backlight, volume, battery, etc.).
  # Font Awesome 6 Free (Solid). Nerd Fonts aren't packaged in Fedora repos.
  fontawesome-6-free-fonts

  # Launcher / window & workspace switcher.
  rofi

  # Calculator scratchpad: qalc (Qalculate! CLI) runs inside a urxvt terminal that
  # i3 keeps in its scratchpad. See "Scratchpad (qalc calculator)" in i3-setup.md.
  qalculate rxvt-unicode

  # Graphical monitor-layout tool (arandr) + automatic layout profiles (autorandr).
  # arandr pulls in xrandr as a dependency. See "Monitor layout" in i3-setup.md.
  arandr autorandr

  # Display backlight control, bound to the brightness keys in the i3 config.
  brightnessctl

  # Sets the desktop wallpaper on the X root window (i3-wallpaper). See
  # "Desktop wallpaper (feh)" in i3-setup.md.
  feh

  # PDF viewer opened by i3-pdf-select (Fedora's evince successor).
  papers

  # Confirmation dialogs for the i3-exit session actions (System mode). See
  # "Power menu / System mode" in i3-setup.md.
  zenity

  # Perl modules used by i3-rename-workspace.
  perl-indirect perl-JSON-Parse perl-Carp-Assert

  # Python module used by i3-move-workspace.
  python3-i3ipc
)

install_packages() {
  echo ">> Installing packages (sudo)..."
  sudo dnf install -y "${PACKAGES[@]}"
}

#-----------------------------------------------------------------------------#
# 2. Symlinks
#-----------------------------------------------------------------------------#

# link SRC DEST : symlink DEST -> SRC, backing up an existing real DEST.
link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    ln -sfn "$src" "$dest"                      # already a symlink: repoint
  elif [[ -e "$dest" ]]; then
    mv "$dest" "$dest.bak"                       # real file: back it up
    echo "   backed up existing $dest -> $dest.bak"
    ln -s "$src" "$dest"
  else
    ln -s "$src" "$dest"
  fi
  echo "   linked $dest -> $src"
}

create_symlinks() {
  echo ">> Creating symlinks..."

  # i3 config
  link "$REPO/dotfiles/i3/config" "$HOME/.config/i3/config"

  # rofi custom theme (arthur-entry; the plain 'arthur' theme is built into rofi)
  link "$REPO/dotfiles/rofi/arthur-entry.rasi" "$HOME/.config/rofi/arthur-entry.rasi"

  # polybar config + per-monitor launch script
  link "$REPO/dotfiles/polybar/config.ini" "$HOME/.config/polybar/config.ini"
  link "$REPO/dotfiles/polybar/launch.sh" "$HOME/.config/polybar/launch.sh"

  # picom compositor config
  link "$REPO/dotfiles/picom/picom.conf" "$HOME/.config/picom/picom.conf"

  # deadd (notification daemon) config + theme. deadd reads ~/.config/deadd/.
  # (The binary itself is not a symlink -- see install_deadd_binary below.)
  link "$REPO/dotfiles/deadd/deadd.yml" "$HOME/.config/deadd/deadd.yml"
  link "$REPO/dotfiles/deadd/deadd.css" "$HOME/.config/deadd/deadd.css"

  # Desktop-entry overrides (add search keywords etc.). ~/.local/share/applications
  # takes precedence over /usr/share/applications.
  for f in "$REPO"/dotfiles/applications/*.desktop; do
    link "$f" "$HOME/.local/share/applications/$(basename "$f")"
  done

  # xscreensaver preferences (~/.xscreensaver, a home-root dotfile -- NOT under
  # ~/.config). Written by xscreensaver-settings; version-controlled so lock/idle
  # timeouts and the saver list survive a reinstall. See "Screen locking" in i3-setup.md.
  link "$REPO/dotfiles/xscreensaver/xscreensaver" "$HOME/.xscreensaver"

  # autorandr global hooks (e.g. postswitch: re-home workspaces for the 'home'
  # profile). The per-profile dirs under ~/.config/autorandr/<name> are EDID-keyed
  # and machine-specific, so we keep hooks at the top level instead.
  link "$REPO/dotfiles/autorandr/postswitch" "$HOME/.config/autorandr/postswitch"

  # ~/bin helper scripts (link every file the repo tracks under bin/)
  for f in "$REPO"/bin/*; do
    link "$f" "$HOME/bin/$(basename "$f")"
  done
}

#-----------------------------------------------------------------------------#
# 3. deadd notification daemon binary
#-----------------------------------------------------------------------------#

# deadd (Linux Notification Center) is NOT packaged in Fedora and must be built from
# source with Haskell stack (see "Notifications (deadd)" in i3-setup.md). The build
# produces a ~104 MB self-contained binary -- too big to version-control -- so we copy
# it into ~/bin as a real file (not a repo symlink like the other bin/ scripts). If the
# build output isn't found, skip with instructions rather than failing: the configs and
# symlinks are installed regardless, and the binary can be added on a later re-run.
DEADD_BUILD_BIN="${DEADD_BUILD_BIN:-$HOME/projects/linux_notification_center/src/.out/deadd-notification-center}"

install_deadd_binary() {
  local dest="$HOME/bin/deadd-notification-center"
  if [[ -x "$DEADD_BUILD_BIN" ]]; then
    echo ">> Installing deadd binary -> $dest"
    mkdir -p "$HOME/bin"
    install -m 755 "$DEADD_BUILD_BIN" "$dest"
  elif [[ -x "$dest" ]]; then
    echo ">> deadd binary already present at $dest (build output not found; keeping it)"
  else
    echo ">> NOTE: deadd not installed -- build output not found at:"
    echo "     $DEADD_BUILD_BIN"
    echo "   Build it first (see \"Notifications (deadd)\" in i3-setup.md), or point"
    echo "   DEADD_BUILD_BIN at the built binary, then re-run ./install.sh."
  fi
}

#-----------------------------------------------------------------------------#
# 4. System keyboard config
#-----------------------------------------------------------------------------#

# Make Caps Lock a Ctrl key (ctrl:nocaps), applied to every keyboard including
# hotplugged ones. localectl writes the managed /etc/X11/xorg.conf.d/00-keyboard.conf,
# which Xorg applies via an InputClass -- no background watcher needed. System-wide
# (also affects the TTY). GNOME-on-Wayland reads its own settings, not this file.
# NOTE: layout 'gb' below matches this machine; change if setting up a different layout.
configure_keyboard() {
  echo ">> Configuring keyboard (Caps->Ctrl) via localectl (sudo)..."
  sudo localectl set-x11-keymap gb pc105 "" ctrl:nocaps
  # Apply to the running X session immediately (no re-login needed).
  command -v setxkbmap >/dev/null && setxkbmap -option ctrl:nocaps || true
}

#-----------------------------------------------------------------------------#
# 5. System timezone
#-----------------------------------------------------------------------------#

# Set the system timezone. Machines have shipped set to a US zone; correct it to
# the UK. Location-specific rather than i3-specific -- change the zone for a
# machine used elsewhere (list options with `timedatectl list-timezones`).
configure_timezone() {
  echo ">> Setting timezone to Europe/London (sudo)..."
  sudo timedatectl set-timezone Europe/London
}

#-----------------------------------------------------------------------------#
# 6. Disable the PC-speaker beep
#-----------------------------------------------------------------------------#

# Silence the motherboard PC-speaker beep by blacklisting the pcspkr kernel
# module system-wide (see dotfiles/modprobe.d/nobeep.conf for the why). This is
# a real /etc file (not a repo symlink -- /etc/modprobe.d is root-owned), so copy
# it in with sudo, then unload the module now so the beep stops without a reboot.
disable_pcspkr_beep() {
  echo ">> Disabling PC-speaker beep (blacklist pcspkr, sudo)..."
  sudo install -m 644 "$REPO/dotfiles/modprobe.d/nobeep.conf" /etc/modprobe.d/nobeep.conf
  # Unload now if loaded (harmless if it isn't); the blacklist keeps it off at boot.
  sudo modprobe -r pcspkr 2>/dev/null || true
}

#-----------------------------------------------------------------------------#
# main
#-----------------------------------------------------------------------------#

main() {
  if [[ "${1:-}" != "--links" ]]; then
    install_packages
    configure_keyboard
    configure_timezone
    disable_pcspkr_beep
  fi
  create_symlinks
  install_deadd_binary
  echo
  echo ">> Done. Log out, then pick the 'i3' session at the gdm login screen."
}

main "$@"
