# shellcheck shell=bash
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
