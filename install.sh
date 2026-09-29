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

  # i3 window manager + status bar + screen saver/locker.
  i3 i3status xscreensaver

  # Launcher / window & workspace switcher.
  rofi

  # PDF viewer opened by i3-pdf-select (Fedora's evince successor).
  papers

  # Perl modules used by i3-rename-workspace.
  perl-indirect perl-JSON-Parse perl-Carp-Assert

  # Python module used by i3-move-workspace.py.
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

  # ~/bin helper scripts (link every file the repo tracks under bin/)
  for f in "$REPO"/bin/*; do
    link "$f" "$HOME/bin/$(basename "$f")"
  done
}

#-----------------------------------------------------------------------------#
# 3. System keyboard config
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
# main
#-----------------------------------------------------------------------------#

main() {
  if [[ "${1:-}" != "--links" ]]; then
    install_packages
    configure_keyboard
  fi
  create_symlinks
  echo
  echo ">> Done. Log out, then pick the 'i3' session at the gdm login screen."
}

main "$@"
