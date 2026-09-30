# shellcheck shell=bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#
# Route SSH passphrase prompts to a GUI dialog instead of the terminal.
#
# Sourced by ~/.bashrc via its ~/.bashrc.d/* loop (symlinked here by install.sh).
#
# The session already runs a single ssh-agent (Fedora's xinitrc-common wraps the
# whole X session in ssh-agent), and ~/.ssh/config has `AddKeysToAgent yes`, so a
# key is decrypted once and then cached in the agent for the rest of the session.
# These two variables make that first prompt a GUI pop-up rather than a terminal
# prompt, matching the old machine's behaviour:
#   SSH_ASKPASS          -- the helper ssh runs to ask for the passphrase. Points at
#                           the ssh-askpass-dark wrapper (~/bin, from bin/), which runs
#                           gnome-ssh-askpass (openssh-askpass package) forced to the
#                           dark GTK theme so the dialog matches the dark session.
#   SSH_ASKPASS_REQUIRE  -- `prefer` makes ssh use the GUI helper even when it has a
#                           controlling terminal; the default only uses it when there
#                           is no tty (so `git push` from a terminal would otherwise
#                           still prompt inline).
#
# See "SSH agent / passphrase caching" in ~/Documents/Machine-Setup/i3-setup.md.
export SSH_ASKPASS="$HOME/bin/ssh-askpass-dark"
export SSH_ASKPASS_REQUIRE=prefer
