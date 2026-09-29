# i3 Window Manager Setup

Steps to set up the [i3 window manager](https://i3wm.org/) on a Fedora Workstation
laptop, alongside the default GNOME desktop.

This is a living document. It records **what to do**, **what gets installed**, and
**why** — so it can be followed again on a future machine. It is updated as we learn
things or change our approach.

> On a fresh machine the fast path is `./install.sh` (see [README.md](README.md)); this
> document explains the reasoning behind what that script does.

---

## Repository structure

The config and scripts are version-controlled here and symlinked into the home directory
(repo = real files, home = symlinks pointing in). Grouped-by-app layout:

```
Machine-Setup/
├── README.md          # quick start
├── i3-setup.md        # this document
├── install.sh         # idempotent: installs packages + creates symlinks
├── .gitignore
├── dotfiles/
│   ├── i3/config              -> ~/.config/i3/config
│   └── rofi/arthur-entry.rasi -> ~/.config/rofi/arthur-entry.rasi
└── bin/               # i3 helper scripts, each -> ~/bin/<name>
```

`install.sh` backs up any pre-existing real file (to `<name>.bak`) before replacing it
with a symlink, so it is safe to re-run. `./install.sh --links` does symlinks only.
(We considered GNU `stow` but chose this simpler explicit approach for now.)

---

## Target environment

These instructions were written against the following machine. Later machines may
differ; note any deviations as you go.

| Property        | Value                                  |
| --------------- | -------------------------------------- |
| OS              | Fedora Linux 44 (Workstation Edition)  |
| Architecture    | x86-64                                 |
| Default desktop | GNOME on **Wayland**                   |
| Display manager | gdm (GNOME Display Manager)            |
| Date set up     | 2026-09-29                             |

---

## Key background: why the extra packages

i3 is an **X11** window manager — it **cannot run on Wayland**. Modern Fedora
Workstation ships GNOME on Wayland and, by default, **does not install the Xorg X
server at all**. So setting up i3 requires two things:

1. **i3 and its companion tools** (status bar, locker, launcher).
2. **The Xorg server and startup glue**, which are otherwise absent.

i3 is installed *alongside* GNOME, not instead of it. It adds a session entry that
gdm shows at the login screen; GNOME remains fully intact and you choose which to log
into each time. gdm can launch an X11 (i3) session even though gdm itself runs on
Wayland.

---

## Step 1 — Install the packages

Run:

```bash
sudo dnf install -y i3 i3status xscreensaver dmenu xorg-x11-server-Xorg xorg-x11-xinit
```

### What each package is and why

| Package                | Purpose                                                                 |
| ---------------------- | ----------------------------------------------------------------------- |
| `i3`                   | The i3 window manager itself (v4.25.1 in the Fedora repo).              |
| `i3status`             | Generates the status line shown in i3's bar (clock, battery, etc.).     |
| `xscreensaver`         | Screen saver **and** locker (v6.16). Used instead of i3lock — see note. |
| `dmenu`                | Lightweight application launcher (bound to Mod+d by default).           |
| `xorg-x11-server-Xorg` | The Xorg X11 display server. **Required** — i3 does not run on Wayland. |
| `xorg-x11-xinit`       | X session startup scripts/glue (`xinitrc`, session plumbing).           |

A terminal is already available via GNOME (gnome-terminal), so none is installed here.

> **Harmless warning during install.** The install may end with:
> `Warning: Pending offline transaction has been invalidated. To reschedule, run:
> dnf5daemon-server`. This is expected and not an error. It means GNOME Software had a
> staged "offline" update (applied on reboot); the live `dnf install` changed the
> package set and invalidated that staged transaction. Look for `Complete!` on the
> last line to confirm success. Any pending updates can just be re-run later.

### Note: xscreensaver instead of i3lock

We chose `xscreensaver` over i3's default `i3lock` because it provides both a
screen saver and locking, with idle-timeout handling.

Unlike i3lock (which is simply invoked on demand to lock), xscreensaver runs as a
**background daemon** that must be started with the session, and locking is triggered
by talking to that daemon:

- Start the daemon from the i3 config, e.g. `exec --no-startup-id xscreensaver -no-splash`.
- Lock on demand with `xscreensaver-command -lock` (bind this to a key in i3).
- Configure idle timeout / lock behaviour with `xscreensaver-settings` (GUI) or by
  editing `~/.xscreensaver`.

These config bindings will be added when we set up the i3 config (see below).

---

## Step 2 — Log into the i3 session

1. Log out of GNOME.
2. At the gdm login screen, click your username.
3. Open the **session menu** (gear icon, bottom-right of the screen).
4. Select **i3**.
5. Enter your password and log in.

Installing the `i3` package places `/usr/share/xsessions/i3.desktop`, which is what
makes i3 appear in that session menu.

---

## Step 3 — First-run config wizard

On the first i3 launch, i3 runs `i3-config-wizard`, which asks whether you want the
**Mod key** to be:

- **Super** (the Windows key) — recommended, avoids clashes with app shortcuts, or
- **Alt**.

It then writes a default config to `~/.config/i3/config`.

---

## Managing the config

The i3 configuration is **version-controlled in this `Machine-Setup` directory** and
symlinked into place, rather than edited under `~/.config/i3` directly. Future machine
setup is then: install packages (Step 1), restore this repo, recreate the symlink.

**Layout**

```
Machine-Setup/dotfiles/i3/config   <- the real, version-controlled file
~/.config/i3/config                -> symlink to the above
```

**Setup performed** (after the first-run wizard generated `~/.config/i3/config`):

```bash
mkdir -p ~/Documents/Machine-Setup/dotfiles/i3
mv ~/.config/i3/config ~/Documents/Machine-Setup/dotfiles/i3/config
ln -s ~/Documents/Machine-Setup/dotfiles/i3/config ~/.config/i3/config
```

**On a fresh machine** (repo already restored to `~/Documents/Machine-Setup`), skip
the wizard's file and just link ours:

```bash
mkdir -p ~/.config/i3
ln -sf ~/Documents/Machine-Setup/dotfiles/i3/config ~/.config/i3/config
```

> Editing note: because `~/.config/i3/config` is a symlink, edit the real file at
> `Machine-Setup/dotfiles/i3/config`. After changes, apply them with `i3-msg reload`
> (or Mod+Shift+c), and validate syntax with `i3 -C -c ~/.config/i3/config`.

## Screen locking / screensaver (xscreensaver)

The generated config used `xss-lock` + `i3lock`; we replaced that with xscreensaver.
The following lines are in the i3 config:

```
exec --no-startup-id xscreensaver -no-splash
bindsym $mod+Shift+x exec --no-startup-id xscreensaver-command -lock
```

- `xscreensaver -no-splash` starts the daemon (idle screensaver + idle-timeout lock).
- **Mod+Shift+x** locks on demand (`xscreensaver-command -lock`). Mod = Super/Win key.
- Configure idle timeout, whether to lock, and which savers run via
  `xscreensaver-settings` (GUI) — it writes `~/.xscreensaver`.
- **Suspend locking is handled automatically:** xscreensaver 6.x spawns
  `xscreensaver-systemd`, which locks before suspend/hibernate via logind. This is why
  `xss-lock` was not needed. (`~/.xscreensaver` is not yet version-controlled — a
  possible future addition once tuned.)

## Terminal (Ptyxis)

Fedora 44 Workstation no longer ships `gnome-terminal` by default; its default terminal
is **Ptyxis** (`/usr/bin/ptyxis`, the modern GNOME terminal). It was already installed.

The problem: i3's default `Mod+Return` runs `i3-sensible-terminal`, which doesn't know
about Ptyxis and falls back down its list to plain **urxvt** (also installed) — an ugly,
unconfigured terminal. We bound Ptyxis explicitly instead:

```
set $term ptyxis
bindsym $mod+Return exec --no-startup-id $term
```

Ptyxis runs fine under i3 (it uses a D-Bus-activated `ptyxis-agent`; no GNOME session
needed). `gnome-terminal` also still works under i3 if ever wanted (`sudo dnf install
gnome-terminal`), but Ptyxis is the current, already-present equivalent.

**Important: `--new-window` is required.** Ptyxis is a single-instance app, so a bare
`ptyxis` just raises the already-open window instead of opening a new terminal. The
binding uses `--new-window` so each Mod+Return spawns a fresh window for i3 to tile.
(`-s`/`--standalone` would also work but starts a whole separate instance — heavier and
with unsynced settings; `--new-window` is preferred.)

## Launcher / window switching (rofi)

rofi (Fedora repo) replaces dmenu as the launcher and adds window/workspace switchers.

**Install:**

```bash
sudo dnf install -y rofi
```

**Bindings currently configured (active):**

```
# Application launcher (drun mode) -- replaces dmenu on $mod+d
bindsym $mod+d exec --no-startup-id rofi -modi drun -show drun -display-drun "Start: " -drun-match-fields "Name#Generic" -show-icons -theme arthur

# Switch windows on the current workspace
bindsym $mod+Shift+Return exec --no-startup-id rofi -modi windowcd -show windowcd -show-icons -theme arthur
```

`arthur` is a theme that ships with rofi (`/usr/share/rofi/themes/`). `dmenu` is left
installed but is no longer bound.

**Custom workspace modi — status.** The old setup had three more rofi bindings backed by
custom scripts (copied into `~/bin`, which Fedora already puts on PATH — confirmed
present in the running i3's environment, so no PATH edit or re-login was needed):

| Binding            | Purpose                          | Script                    | Status |
| ------------------ | -------------------------------- | ------------------------- | ------ |
| `$mod+equal`       | Switch to a workspace            | `i3-switch-workspace.sh`  | ✅ working (bash, no deps) |
| `$mod+Shift+equal` | Move focused container to a ws   | `i3-move-container.sh`    | ✅ working (bash, no deps) |
| `$mod+Shift+minus` | Move workspace to another output | `i3-move-workspace.py`    | ✅ working (`python3-i3ipc` installed) |

Notes:

- `i3-move-workspace.py` imports the `i3ipc` Python library, provided by
  `python3-i3ipc` (v2.2.1, Fedora repo) — **installed**. Its shebang is
  `#! /bin/env python3` (works; `/bin` is usr-merged to `/usr/bin`).
- The switch-workspace script was originally `i3_switch_workspaces.sh` (underscores), so
  a `cp i3-*` glob had skipped it. It was later copied and **renamed** to
  `i3-switch-workspace.sh` (hyphens) for consistency; the binding uses the new name.
- `$mod+Shift+question` → `i3-rename-workspace` (Perl) — **working.** Requirements:
    - Perl modules `perl-indirect`, `perl-JSON-Parse`, `perl-Carp-Assert` (Fedora repo)
      — `sudo dnf install -y perl-indirect perl-JSON-Parse perl-Carp-Assert`.
      (`autovivification` was already present.)
    - rofi theme `arthur-entry` — present at `~/.config/rofi/arthur-entry.rasi`.
  The old binding used an absolute path (`/home/andrew/bin/i3-rename-workspace`); the new
  one uses the bare name (on PATH via ~/bin).

  **GiveHelp retired.** The script originally loaded a custom module
  (`use lib "$ENV{HOME}/lib"; use GiveHelp qw/usage/;`) whose only job was to auto-provide
  `-h`/`--help` from the script's POD — and which itself dragged in the non-core `boolean`
  module. That was replaced with the standard core idiom:

  ```perl
  use Getopt::Long;
  use Pod::Usage;
  my $help;
  GetOptions ('help|h' => \$help) or pod2usage (2);
  pod2usage (-verbose => 1) if ($help);
  ```

  This keeps both `-h` and `--help` (verbose level 1, matching the original) using only
  core Perl, and removes the `GiveHelp.pm` + `perl-boolean` dependencies from the setup.
  `~/lib/GiveHelp.pm` (and `Boolean.pm`) are no longer needed by anything in `~/bin`.

**Reproducibility — done.** All 10 `~/bin/i3-*` scripts and the rofi `arthur-entry.rasi`
theme are now version-controlled in this repo (`bin/`, `dotfiles/rofi/`) and symlinked
back into the home directory, and `install.sh` records the package list. `~/lib`
(`GiveHelp.pm`, `Boolean.pm`) is intentionally NOT included — it was retired when
`i3-rename-workspace` was modernized to core Perl.

Other i3 helper scripts also found in `~/bin` (not all wired to bindings yet):
`i3-fix-workspace-placement.py`, `i3-pdf-select`, `i3-presentation-mode-warning`,
`i3-setup-keyboard`, `i3-toggle-selected-output.py`, `i3-toggl-select`,
`i3-rename-workspace`.

## Other helper-script bindings

Additional bindings from the old setup, backed by scripts in `bin/`:

| Binding        | Script                          | Purpose                              | Status |
| -------------- | ------------------------------- | ------------------------------------ | ------ |
| `$mod+Tab`     | `i3-toggle-selected-output.py`  | Cycle focus through active outputs    | ✅ working (`python3-i3ipc`) |
| `$mod+Shift+p` | `i3-pdf-select`                 | Fuzzy-find a PDF under `~/Documents` and open it | ✅ working (rofi + `papers`) |
| `` $mod+grave `` | `i3-toggl-select`             | Toggl time-tracker project switcher   | ❌ disabled — needs `toggl` CLI |

Notes / fixes applied:

- **`i3-pdf-select`**: had a hardcoded `docroot=/home/andrew/Documents/` → changed to
  `${HOME}/Documents/`. It called **`evince`**, which Fedora 44 replaced with **`papers`**
  (evince's successor) → switched to `papers` (added to `install.sh`). Uses the built-in
  rofi `arthur` theme in dmenu mode.
- **`i3-toggle-selected-output.py`**: uses `python3-i3ipc` (already installed); shebang
  `#! /bin/env python3` works. No changes needed.
- **`i3-toggl-select`** (DISABLED): a personal Toggl time-tracking integration. It shells
  out to a `toggl` CLI that is **not packaged in dnf** and requires a configured Toggl
  account/API token. It also pokes `py3status`/`i3status` with `killall -USR1` to refresh
  the bar (harmless if `py3status` is absent). Binding is staged (commented) in the config
  pending a decision on whether to keep using Toggl.

## Follow-ups / ideas

- Version-control `~/.xscreensaver` once locking preferences are tuned.
- Consider `picom` (compositor), a nicer bar (e.g. `polybar`), and `rofi` in place of
  dmenu, if desired later.

---

## Change log

- **2026-09-29** — Initial document created. Machine: Fedora 44 Workstation, GNOME/
  Wayland, gdm. Packages chosen; install not yet run.
- **2026-09-29** — Swapped `i3lock` → `xscreensaver` (v6.16, `updates` repo) for
  screen locking. Unlike i3lock it runs as a daemon started from the session; added a
  note covering how to start/lock/configure it.
- **2026-09-29** — Install run and verified successful. Versions: i3 4.25.1,
  i3status 2.15, xscreensaver 6.16, dmenu 5.4, xorg-x11-server-Xorg 21.1.24,
  xorg-x11-xinit 1.4.3. `/usr/share/xsessions/i3.desktop` present (gdm will show i3).
  Noted the harmless "pending offline transaction invalidated" warning.
- **2026-09-29** — First i3 login done; wizard chose Mod = Super (Mod4). Moved the
  generated config into `dotfiles/i3/config` and symlinked it; documented the layout
  and fresh-machine steps. Replaced the wizard's `xss-lock`/`i3lock` block with
  `xscreensaver -no-splash` + a Mod+Shift+x lock binding. Config validated (`i3 -C`),
  i3 reloaded, daemon started. **Discovery:** xscreensaver 6.x auto-starts
  `xscreensaver-systemd`, which locks before suspend — so xss-lock is unnecessary;
  corrected the earlier "suspend auto-lock not wired up" caveat accordingly.
- **2026-09-29** — Terminal: found i3-sensible-terminal was falling back to urxvt
  (gnome-terminal not installed on Fedora 44; default is now Ptyxis). Bound
  `Mod+Return` to `ptyxis` explicitly. Validated, reloaded, test-launched OK.
- **2026-09-29** — Fixed second-terminal problem: bare `ptyxis` (single-instance) just
  raised the existing window. Changed binding to `ptyxis --new-window` so each
  Mod+Return opens a new window. Confirmed working.
- **2026-09-29** — rofi (Fedora repo, v2.0.0): rebound `$mod+d` from dmenu to rofi
  `drun`, and added `$mod+Shift+Return` window switcher (`windowcd`, arthur theme).
  Config validated but not yet reloaded (rofi not installed at time of writing). Three
  custom workspace modi from the old setup left unbound pending the original scripts
  (were in `/home/andrew/bin`); placeholder comment left in the config.
- **2026-09-29** — Got the full original binding lines. Updated `$mod+d` to the complete
  launcher (`-drun-match-fields "Name#Generic" -show-icons -theme arthur`). Staged the
  three workspace bindings as commented lines in the config (exact originals). Still need
  the *contents* of the 3 scripts (`i3_switch_workspaces.sh`, `i3-move-container.sh`,
  `i3-move-workspace.py`) — binding lines only reference them by name. rofi still not
  installed at this point.
- **2026-09-29** — rofi 2.0.0 installed (arthur theme confirmed). Scripts copied to
  `~/bin` (already on i3's PATH — no re-login needed). Enabled `$mod+Shift+equal`
  (i3-move-container.sh, smoke-tested OK) and `$mod+Shift+minus` (i3-move-workspace.py,
  pending `python3-i3ipc`). `$mod+equal` left disabled: `i3_switch_workspaces.sh` was not
  copied (underscore name skipped by an `i3-*` glob). Flagged that ~/bin scripts still
  need version-controlling into the repo.
- **2026-09-29** — Restored the switch-workspace script, renamed to
  `i3-switch-workspace.sh` (hyphens). Updated the `$mod+equal` binding to the new name and
  enabled it; validated, reloaded, smoke-tested OK.
- **2026-09-29** — Installed `python3-i3ipc`; `$mod+Shift+minus` (move workspace to
  output) confirmed working. All three custom rofi workspace bindings now functional.
- **2026-09-29** — Looked at enabling `$mod+Shift+question` (i3-rename-workspace, Perl).
  Found unmet deps: perl modules indirect/JSON::Parse/Carp::Assert (all in Fedora repo)
  and the custom `~/lib/GiveHelp.pm` (not yet copied; `~/lib` missing). rofi theme
  `arthur-entry` already present. Staged the binding (commented, bare-name form) pending
  those; config validated. Added `~/lib` + rofi config to the reproducibility TODO.
- **2026-09-29** — Reviewed the custom `GiveHelp.pm` (auto `--help` from POD; written
  2003). Its behaviour is now standard in core `Getopt::Long` (`auto_help`) + `Pod::Usage`.
  Chose to modernize: rewrote `i3-rename-workspace`'s help handling to the core idiom and
  retired `GiveHelp.pm` (also drops the non-core `perl-boolean` dep). Only that one script
  used it. Perl modules installed; `perl -c` clean; `--help` tested. Enabled the
  `$mod+Shift+question` binding; validated and reloaded. All original rofi bindings now
  functional.
- **2026-09-29** — Version-controlled everything: moved the 10 `~/bin/i3-*` scripts into
  `bin/` and `arthur-entry.rasi` into `dotfiles/rofi/`, symlinked all back into home
  (verified scripts still run). Added `install.sh` (packages + idempotent symlinks),
  `README.md`, `.gitignore`. Dropped `dmenu` from the package list (replaced by rofi).
  Chose grouped-by-app layout over GNU stow. `git init` + initial commit.
- **2026-09-29** — Wired three more bindings. `$mod+Tab`
  (i3-toggle-selected-output.py) and `$mod+Shift+p` (i3-pdf-select) enabled and working;
  fixed i3-pdf-select's hardcoded path (`/home/andrew`→`$HOME`) and swapped `evince`→
  `papers` (added `papers` to install.sh). `$mod+grave` (i3-toggl-select) left disabled —
  needs the un-packaged `toggl` CLI + a Toggl account; binding staged commented.
