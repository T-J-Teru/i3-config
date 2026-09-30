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

## Status bar (polybar)

polybar replaces the built-in i3bar + i3status. (i3status is kept installed as a fallback; the
old `bar {}` block is preserved commented-out in the i3 config.)

**Install:**

```bash
sudo dnf install -y polybar fontawesome-6-free-fonts
```

`fontawesome-6-free-fonts` supplies the glyph icons used by the status modules. Nerd Fonts
aren't packaged in Fedora's repos, so Font Awesome 6 Free (Solid) is the reliable choice.

**Files** (version-controlled under `dotfiles/polybar/`, symlinked by `install.sh`):

- `~/.config/polybar/config.ini` — the bar definition and modules.
- `~/.config/polybar/launch.sh` — starts **one bar per connected monitor**. The primary output
  gets the `main` bar (system tray + power glyph); every other output gets the `secondary` bar,
  which is identical minus the tray and the power glyph. Launched from the i3 config via
  `exec_always --no-startup-id $HOME/.config/polybar/launch.sh`, so it re-runs on i3 restart and
  can be re-run any time to respawn the bars.

**Modules configured:** i3 workspaces (left) and, on the right: backlight, volume (pulseaudio),
disk usage, memory, cpu, wifi, battery, clock, and — **on the primary display only** — a
**notifications** bell and a **power** glyph, plus the tray. (No window-title module.) Both are
`custom/text` modules: the power glyph's `click-left` runs `i3-power-menu` (see "Power menu"
below); the bell's `click-left` runs `pkill -SIGUSR1 -x deadd-notificat`, which toggles the deadd
notification center open/closed (the same SIGUSR1 toggle noted under "Notifications (deadd)").

**Primary-only bell / power glyph / tray.** polybar can't conditionally drop a module from a
single bar's `modules-*` list (an `${env:...}` placeholder there is read as a literal module name,
not interpolated), so the difference is expressed as two bars: `[bar/secondary]` uses `inherit =
bar/main` and overrides only `modules-right` to omit `notifications` and `power`. `launch.sh` runs
`polybar main` on the primary output and `polybar secondary` on the rest. The tray is separate —
gated by the `TRAY_POSITION` env var (`right` on primary, `none` elsewhere).

**Click-to-details.** The bar only has room for a glyph + one number per module, so the
`cpu`, `memory` and `battery` modules are left-clickable: clicking one fires a deadd
notification with the fuller breakdown — CPU shows load averages + top processes by CPU,
memory shows usage + top processes by RAM, battery shows charge/state/draw and time-remaining.
The helper is `~/bin/polybar-detail` (tracked as `bin/polybar-detail`, auto-symlinked by
`install.sh`); it reuses one popup on repeated clicks (`notify-send -p`/`-r`, id stashed in
`$XDG_RUNTIME_DIR`) and marks them `transient` so they stay out of the notification-center
history. It needs `upower` (battery) plus the standard `nproc`/`free`/`ps`.

Two implementation notes worth knowing:
- The click is wired with a **`%{A1:polybar-detail <what>:}<label>%{A}` action tag** in the
  module's `format` (for battery, in each `format-charging`/`-discharging`/`-full`), *not* a
  module-level `click-left`. A bare `click-left` doesn't fire reliably on **internal** modules
  in polybar 3.7.2 (it works for `custom/*` like the power glyph, hence the difference).
- The detail popups run to ~8 lines, so deadd's `max-lines-in-body` is raised 4 → 10 in
  `deadd.yml` (at 4, only the first process showed and the body was ellipsized).

**Fonts / glyph icons:** two fonts are declared in `[bar/main]` — `font-0 = monospace` for text
and `font-1 = Font Awesome 6 Free:style=Solid` for icons. Modules select the icon font with the
`%{T2}` token (`%{T1}` = font-0, `%{T2}` = font-1, `%{T-}` reverts). Icons in use: sun
(backlight), speaker that ramps with the volume level / crossed-out when muted, hard-drive
(disk), memory chip (RAM), microchip (CPU), wifi, a battery that fills with charge (plus a bolt
while charging), and a calendar (clock). If any icon shows as an empty box (tofu), the font is
missing — install `fontawesome-6-free-fonts`. The glyph codepoints are stored as literal UTF-8
in `config.ini`; they were injected from ASCII placeholders via a `perl -CSD` pass to guarantee
the exact Font Awesome codepoints.

**Machine-specific values** baked into `config.ini` (change per machine; commands to find them
are noted inline in the file): battery `BAT0` / adapter `AC` (`/sys/class/power_supply`), wifi
`wlp0s20f3` (`/sys/class/net`), backlight `intel_backlight` (`/sys/class/backlight`).

**Multi-monitor / hotplug:** `screenchange-reload = true` makes each bar reload on output
changes. To fully respawn bars for a newly-connected monitor after dock/undock, re-run
`launch.sh` (a natural future addition to the autorandr `postswitch` hook).

**Activate / reload:** after editing the config, `~/.config/polybar/launch.sh` (or `$mod+Shift+r`
to restart i3, which re-runs it). Per-monitor logs go to `/tmp/polybar-<output>.log` — check
there if a bar doesn't appear (e.g. a module type unsupported by the packaged build).

## Power menu (i3-power-menu)

`~/bin/i3-power-menu` (tracked as `bin/i3-power-menu`, symlinked by `install.sh`) is a small
rofi menu offering **Lock / Logout / Suspend / Reboot / Shutdown**. It's reachable two ways:

- the **power glyph** at the right end of polybar (`custom/text` module, `click-left`), and
- the **`$mod+Escape`** keybinding in the i3 config.

The actions go through systemd-logind (`systemctl suspend|reboot|poweroff`, `i3-msg exit`,
`xscreensaver-command -lock`), so the active local session runs them via polkit with **no sudo**.
(Reboot/shutdown may prompt for authentication if another user session is also logged in.) The
menu labels carry Font Awesome glyphs generated with `printf '\uXXXX'`; pango falls back to the
FA font per-glyph, so they render even though the rofi `arthur` theme's font isn't FA.

## Compositor (picom)

i3 has no compositor of its own, so without one there's no translucency, shadows or
rounded corners, and RGBA window areas render as solid black. picom fills that gap —
most visibly it makes the deadd notification cards (below) read as frosted-glass
panels instead of black rectangles, but it lifts the whole desktop (soft drop
shadows, rounded corners).

**Install:**

```bash
sudo dnf install -y picom
```

**File:** `~/.config/picom/picom.conf` (tracked as `dotfiles/picom/picom.conf`,
symlinked by `install.sh`).

**Autostart:** from the i3 config —

```
exec_always --no-startup-id "pkill -x picom; sleep 0.5; exec picom --config $HOME/.config/picom/picom.conf"
```

picom has no `--replace`, and `exec_always` re-runs on every i3 restart, so the line
kills any running instance first to avoid stacking a second compositor (each would
fight over drawing and you'd get flicker).

**What's configured:** `glx` backend with `vsync` (needed for smooth blur/shadow on
the Intel iGPU); drop shadows (excluded on docks so polybar stays flat); 12px rounded
corners (matching the deadd card radius; docks excluded); `dual_kawase` blur behind
translucent windows; short fade-in/out. `detect-client-opacity` honours app-set
opacity. GTK client-side-decoration shadow regions are excluded via the
`_GTK_FRAME_EXTENTS@` selector (note: the older `@:c` type-suffix form is deprecated
in current picom).

**Dim inactive windows.** `inactive-dim = 0.5` fades every non-focused window to half
brightness so the active one is easy to spot (measured: a window drops to exactly 0.50×
its focused brightness). This replaces the old machine's separate `window-dimmer` script,
which ran a second compositor purely for compton's `--inactive-dim`; now it just folds
into the one picom we already run. `focus-exclude` lists windows that are never dimmed:
docks (polybar), the desktop/wallpaper, `notification` windows and the deadd center
(so pop-ups stay bright), `rofi`, i3 frame decorations, xscreensaver, and unnamed
transient helpers. The dock/notification/deadd excludes are new here (the old machine
had neither polybar nor deadd); the rest port the old script's `--focus-exclude` rules.

## Desktop wallpaper (feh)

i3 draws nothing on the X root window, so without help the desktop is a blank grey. `feh`
paints it — the same lightweight tool the old machine used (it left a `~/.fehbg`). In a
tiler the wallpaper is only visible briefly before a window covers it, so this is kept
deliberately simple: a random image per monitor, re-rolled on each i3 start.

`bin/i3-wallpaper` collects the images under `~/Pictures/Wallpapers` (recursively — the set
lives in a `digitalblasphemy/` subdir) and runs:

```
feh --bg-fill --randomize <all images>
```

`--bg-fill` scales/crops each image to fill its monitor without distortion; given several
files feh assigns **one image per monitor**, and `--randomize` shuffles the list first, so
each monitor gets its own random image every run. feh also writes `~/.fehbg` (a re-runnable
restore script) as a side effect.

It's wired in two places:

- **i3 config** — `exec_always --no-startup-id i3-wallpaper`, so the wallpaper re-rolls on
  every i3 start/restart.
- **autorandr `postswitch` hook** — repaints after any layout change, so on dock/undock each
  now-active monitor gets a correctly-sized image for the new geometry.

The script no-ops with a message if feh isn't installed or the directory has no images.
Swap in your own pictures by dropping them in `~/Pictures/Wallpapers` (or pass a different
directory as the first argument). `feh` is installed by `install.sh`.

## Notifications (deadd)

i3 ships no notification daemon, so out of the box `notify-send` fails with
`GDBus.Error…ServiceUnknown: The name is not activatable` — nothing owns the
`org.freedesktop.Notifications` D-Bus name. We chose **deadd** (the "Linux
Notification Center", a Haskell/GTK3 daemon) over the lightweight options (dunst,
etc.) because it looks modern and slick and also provides a slide-out **notification
center** (history + a clock/date panel), all fully CSS-themeable. With picom (above)
its cards render as translucent frosted-glass panels.

deadd is **not packaged in Fedora**, so it's built from source with Haskell `stack`,
then the resulting binary is installed to `~/bin` and autostarted from i3.

### Build from source

We build from a **personal fork** rather than upstream, carrying two local commits on
`master`:

1. **Fedora 44 build fix** — upstream doesn't compile against `gi-glib` 2.0.30 (it
   dropped `unixSignalAdd`); handle SIGUSR1 via `installHandler` + `idleAdd` instead.
2. **Multi-monitor center resize** — `setNotificationCenterPosition` (in
   `NotificationCenter.hs`) sized the center with `windowSetDefaultSize`, which GTK only
   honours on a window's *first* map; on later shows it's a no-op, so the center kept its
   first monitor's height and overlapped polybar (or left a big gap) when reopened on a
   monitor of a different height. Added a `windowResize` call so it re-sizes on every
   show. Needed here because the two monitors differ in height (1080 vs 1200).

**1. Install the build dependencies (dnf).** Haskell `stack` plus the C libraries and
headers the GTK/GLib/introspection Haskell bindings compile against:

```bash
sudo dnf install -y \
  stack \
  gtk3-devel cairo-devel pango-devel \
  gobject-introspection-devel \
  libX11-devel libXrender-devel \
  libconfig-devel
```

**2. Clone the fork and build `master`:**

```bash
git clone git@github.com:T-J-Teru/linux_notification_center.git
cd linux_notification_center      # Makefile is at the repo root
make
```

`make` runs `stack setup` (which downloads the GHC the resolver pins — `lts-22.28` →
GHC 9.6.6, a one-off ~2 GB fetch) then `stack install --local-bin-path .out`. The
first build is slow (compiles the whole dependency tree). The result is a
self-contained ~104 MB binary at **`.out/deadd-notification-center`**.

Run it to test: `./.out/deadd-notification-center &` then `notify-send "hello" "it works"`.
Toggle the notification center with `pkill -SIGUSR1 -x deadd-notificat` (the process
name truncates to 15 chars, so match `deadd-notificat`, and prefer `pkill -x` over
`pkill -f` — the latter can match your own shell's command line and kill it).

### Install & autostart

The ~104 MB binary is a build artifact, so it is **not** version-controlled or
symlinked from the repo like the `bin/` scripts. Instead `install.sh` copies it into
`~/bin` as a real file (on `$PATH`):

```bash
install -m 755 .out/deadd-notification-center ~/bin/deadd-notification-center
```

`install.sh` does this automatically via `install_deadd_binary`, reading the build
output from `~/projects/linux_notification_center/src/.out/` by default (override with
the `DEADD_BUILD_BIN` env var). If the build output isn't found it prints a note and
skips, rather than failing — build deadd first, then re-run `./install.sh`.

Autostart is from the i3 config, guarded like picom so an i3 restart doesn't leave two
daemons fighting over the D-Bus name:

```
exec_always --no-startup-id "pkill -x deadd-notificat; sleep 0.5; exec env GTK_THEME=Adwaita:dark deadd-notification-center"
```

`GTK_THEME=Adwaita:dark` is deliberate: deadd doesn't honour GNOME's `prefer-dark`
portal preference, so under the plain (light) Adwaita theme it renders **symbolic
(monochrome) notification icons** — most visibly the volume/brightness OSD sun and
speaker — in the light theme's dark-grey foreground, which reads as muted on the dark
card. Symbolic icons are recoloured from the GTK theme's foreground, *not* from CSS
(deadd loads them via `imageSetFromIconName`, which ignores CSS `color`), so the fix
lives in the launch environment rather than `deadd.css`. Forcing the dark theme flips
them to a bright near-white; full-colour app icons (Firefox etc.) render vividly either
way and are unaffected.

### Configuration & theme

deadd resolves its config dir via `getXdgDirectory XdgConfig ""`, i.e. it reads
**`~/.config/deadd/deadd.yml`** (behaviour) and **`~/.config/deadd/deadd.css`**
(appearance). Both are version-controlled here under `dotfiles/deadd/` and symlinked
into place. The CSS is a dark theme matching the polybar palette (translucent cards,
rounded corners, a red critical-urgency variant, and a large clock in the center);
the translucency/blur only looks right with picom running. Note symbolic icon
brightness is *not* a CSS setting — see `GTK_THEME` in the autostart above.

**Clearing polybar.** The notification center is drawn full screen height, so by
default its bottom edge sits *underneath* polybar (which docks at the bottom of every
monitor). deadd reserves space for a bottom bar via the `margin-bottom` key: it draws
the center `screenHeight − margin-top − margin-bottom` tall, so `margin-bottom: 32`
(polybar is ~32px = 24pt @ 96dpi) shrinks the center to stop flush above the bar
instead of overlapping it. The value is the same for both monitors since both bottom
bars are the same height. (Internally deadd maps `margin-top`/`margin-bottom` to its
top/bottom bar-height settings — see `NotificationCenter.hs`.) On a multi-monitor setup
with **differently-sized** monitors this only behaves correctly with the fork's
`windowResize` commit (see "Build from source" above); without it the center keeps the
height of whichever monitor it was first opened on.

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

Notes / fixes applied:

- **`i3-pdf-select`**: had a hardcoded `docroot=/home/andrew/Documents/` → changed to
  `${HOME}/Documents/`. It called **`evince`**, which Fedora 44 replaced with **`papers`**
  (evince's successor) → switched to `papers` (added to `install.sh`). Uses the built-in
  rofi `arthur` theme in dmenu mode.
- **`i3-toggle-selected-output.py`**: uses `python3-i3ipc` (already installed); shebang
  `#! /bin/env python3` works. No changes needed.
- **`i3-toggl-select`** (Toggl time-tracker switcher): **dropped.** It depended on a
  `toggl` CLI not packaged in dnf plus a configured Toggl account, and is no longer used.
  Binding, script (`bin/i3-toggl-select`), and its `~/bin` symlink were removed.

## Keyboard: Caps Lock as Ctrl

Preference: Caps Lock should act as an extra Ctrl key (`ctrl:nocaps`).

The old setup used a custom `i3-setup-keyboard` script — a background loop that ran
`setxkbmap -option ctrl:nocaps`, then used `inotifywait` on `/dev/input/` to re-apply it
whenever a keyboard was hotplugged (because `setxkbmap` only configures currently-attached
devices). That needed `inotify-tools` and a permanent background process.

**Replaced with the native mechanism.** Xorg applies XKB options from an `InputClass`
(`MatchIsKeyboard "on"`) to every keyboard as it is plugged in, so no watcher is needed.
That config is managed by `localectl`:

```bash
sudo localectl set-x11-keymap gb pc105 "" ctrl:nocaps
```

This writes `XkbOptions "ctrl:nocaps"` into `/etc/X11/xorg.conf.d/00-keyboard.conf`
(the file was already localectl-managed with `XkbLayout "gb"`). To apply to the running
X session without a re-login, also run `setxkbmap -option ctrl:nocaps` once
(`install.sh` does this).

Notes:

- System-wide (needs sudo; also affects the virtual console). Fine for a personal remap.
- The GNOME session runs on **Wayland**, which reads its own keyboard options (gsettings),
  not this file. This covers **i3 (X11)** fully; a separate `gsettings` tweak would be
  needed to get the same remap inside GNOME.
- `i3-setup-keyboard` and its `~/bin` symlink were removed; no `inotify-tools` needed.
- The `localectl` command uses layout `gb` (this machine). Change it for a different layout.

## Timezone

The machine shipped set to a US timezone (`US/Eastern`/EDT), so `date` and the i3bar clock
showed the wrong local time even though UTC/NTP were correct. Fix (system-wide, needs sudo):

```bash
sudo timedatectl set-timezone Europe/London
```

`install.sh` applies this (`configure_timezone`). The i3bar clock updates on its next i3status
tick — no restart needed. Location-specific, not i3-specific: change the zone for a machine
used elsewhere (`timedatectl list-timezones` lists the options; `timedatectl status` shows the
current one).

## Silencing the PC-speaker beep

The motherboard PC speaker emits a loud hardware "beep" on bell events (readline
tab-completion, a shell error, etc.). The old machine masked it with a per-session `xset -b`
in the i3 autostart, but that only disables the *X server's* bell and must re-run every login.
The definitive fix is to blacklist the **`pcspkr`** kernel module that drives the speaker,
which silences it system-wide (X *and* the TTY/console) permanently:

```bash
# dotfiles/modprobe.d/nobeep.conf, installed to /etc/modprobe.d/nobeep.conf
blacklist pcspkr
blacklist snd_pcsp
install pcspkr /bin/true
install snd_pcsp /bin/true
```

`install.sh` applies this (`disable_pcspkr_beep`): it copies the file in with sudo (it's a
root-owned `/etc` file, not a repo symlink) and runs `sudo modprobe -r pcspkr` so the beep
stops immediately without a reboot; the blacklist keeps it off at every boot thereafter.
`snd_pcsp` (the ALSA equivalent) isn't loaded on this machine but is blacklisted for good
measure. Verify with `lsmod | grep pcspkr` (should print nothing).

## Monitor layout (arandr + autorandr)

GNOME has its own Settings → Displays panel, but that only affects the Wayland session;
i3 (X11) needs an xrandr-based tool. Two packages cover it:

- **`arandr`** — a graphical, drag-and-drop front-end for `xrandr`. Launch it, arrange the
  monitors, set primary/resolution/orientation, and click Apply. Changes are live but not
  persistent. (arandr pulls in `xrandr`, which is otherwise not installed.)
- **`autorandr`** — snapshots a layout and reapplies it automatically when the same set of
  monitors is detected (via its udev hook on dock/undock, and via i3 on start).

Workflow:

```bash
arandr                     # arrange graphically, Apply
autorandr --save home      # save the current layout as a named profile
autorandr --list           # list profiles
autorandr --change         # reapply whichever profile matches connected outputs
```

The i3 config runs `exec_always --no-startup-id autorandr --change` on every start/restart,
so the matching layout is restored automatically when i3 comes up.

**Not version-controlled:** profiles live in `~/.config/autorandr/<name>/` and are keyed to
the connected monitors' EDIDs, so they are machine-specific. On a new machine, recreate them:

```bash
# Docked (laptop + external), arranged with arandr:
autorandr --save home
# Undocked (laptop only):
autorandr --save mobile
```

**Two profiles are needed for hotplug to work in both directions** (see below): `home`
(laptop + external monitor) and `mobile` (laptop only). autorandr only ever switches *to a
saved profile whose fingerprint matches the connected outputs* — with only `home` saved,
unplugging matches nothing and i3 is left in the two-monitor layout. `mobile` gives it a
laptop-only target to switch to. On this machine: external = `DP-2-3`, laptop = `eDP-1`.

### Automatic hotplug switching

The `autorandr` package ships a udev rule (`/usr/lib/udev/rules.d/40-monitor-hotplug.rules`)
that, on any monitor plug/unplug, runs `systemctl start autorandr.service` → `autorandr
--batch --change`. This auto-selects the matching profile when you dock/undock. The udev rule
is active out of the box; the `autorandr.service` being `disabled` only affects its separate
resume-from-sleep trigger, not hotplug. `--batch` sets `DISPLAY`/`XAUTHORITY` per user session
so the switch (and its hooks) run inside the graphical session (verified in the journal:
`Running autorandr as aburgess for display :0`).

This machine uses an Intel iGPU (i915) + Xorg modesetting driver, and the external monitor is
DisplayPort-MST (name `DP-2-3` = branch `DP-2`, downstream port `3`) via the dock/USB-C. X
*does* detect MST plug/unplug here (confirmed: `xrandr` flips the connector
connected↔disconnected on hotplug), so automatic switching works. The earlier "unplug did
nothing" symptom was purely the missing `mobile` profile, not a detection failure.

Each hotplug transition now runs a real off→on `xrandr` modeset: on unplug `mobile` turns
`DP-2-3` **off**, and on replug `home` turns it back **on** with a fresh mode. That off→on
sequence is what cures the **stale-link blank screen** seen previously — when no profile switch
happened the DP/MST link was never disabled and re-enabled, so the panel stayed black after
replug even though everything *looked* configured. End-to-end unplug/replug was tested and
works in both directions, including the 20-29 workspace re-homing.

> **Two hard-won gotchas:**
> 1. **`xrandr` connection/mode state is not ground truth for "is there a picture."** X can
>    report `DP-2-3 connected 1920x1200+0+0` while the physical panel is black (dead link).
>    Only your eyes confirm recovery.
> 2. **Recovery requires turning the output OFF then ON — not just re-applying the mode.**
>    `autorandr --change --force` (which re-asserts the *same* mode on a stale link) did **not**
>    recover a stuck panel in testing. What works is an explicit off/on cycle:
>    ```bash
>    xrandr --output DP-2-3 --off && sleep 1 && autorandr --load home --force
>    ```
>    (The automatic path gets this for free because `mobile` disables the output before `home`
>    re-enables it.)

Note: plain `autorandr --load <profile>` skips a profile that doesn't match the currently
connected outputs; add `--force` to apply it anyway (used for testing `mobile` while docked).
`autorandr --change` also only fires hooks when the profile actually changes (`Config already
loaded` otherwise).

### Re-homing workspaces on the "home" profile (postswitch hook)

Preference: workspaces numbered 20-29 should live on the external monitor. `autorandr` runs a
global `postswitch` hook after every switch and exposes the activated profile in
`$AUTORANDR_CURRENT_PROFILE`. The hook (version-controlled at `dotfiles/autorandr/postswitch`,
symlinked to `~/.config/autorandr/postswitch`) runs `i3-fix-workspace-placement.py` only for
the `home` profile:

```sh
case "$AUTORANDR_CURRENT_PROFILE" in
    home) i3-fix-workspace-placement.py ;;
esac
```

`i3-fix-workspace-placement.py` (uses `python3-i3ipc`) moves every existing workspace numbered
20-29 to the external output, then restores focus. It is a no-op unless **both** expected
outputs are active, so it is safe to run any time.

- The hook is kept as a **global** hook, not inside `~/.config/autorandr/home/`, because the
  per-profile directory is EDID-keyed and not version-controlled.
- **Output names are machine-specific.** On this laptop: laptop = `eDP-1`, external = `DP-2-3`
  (the old machine used `DP-3`). Both are set near the top of the script; check names with
  `i3-msg -t get_outputs` and update them on a new machine.
- You can still run `i3-fix-workspace-placement.py` by hand at any time.

### Pinning the numbered workspaces to the laptop

Complementing the 20-29-on-external rule, the ten numbered workspaces (1-10, the number-row
keys) are **pinned to the primary output** so they always open on the laptop panel — which is
where they're expected regardless of which monitor happens to have focus. This is a static i3
directive (not a script), one line per workspace in the config:

```
workspace $ws1 output primary
...
workspace $ws10 output primary
```

The special **`primary`** keyword is used rather than a hardcoded `eDP-1`, so it stays
machine-independent: it resolves to whatever xrandr marks primary (the laptop panel here, set
by autorandr). An assignment takes effect when the workspace is next created/shown — verified
that opening a fresh numbered workspace while focused on the external monitor still lands it on
the laptop.

### Finding ARandR in the launcher by "Display"

The packaged `arandr.desktop` has `Name=ARandR` and `GenericName=Screen Settings`, so rofi
finds it under "arandr" or "screen" but not "Display". A **user desktop override** at
`~/.local/share/applications/arandr.desktop` (version-controlled at
`dotfiles/applications/arandr.desktop`, symlinked by `install.sh`) adds a `Keywords=` line:

```ini
Keywords=Display;Monitor;Screen;Layout;Resolution;Output;
```

Files in `~/.local/share/applications` override those in `/usr/share/applications` and
survive package updates. For rofi to actually search that field, the `$mod+d` binding must
include `keywords` in `-drun-match-fields`. The old value `"Name#Generic"` was not valid
syntax (rofi fields are lowercase, comma-separated), so it was corrected to
`name,generic,keywords`. Now typing "Display" (or Monitor/Layout/…) surfaces ARandR.

**i3 quoting gotcha:** i3 treats a comma as a *command separator* (e.g. `move left, resize …`),
so an unquoted `-drun-match-fields name,generic,keywords` makes i3 try to run `generic` /
`keywords` as commands and the binding fails at press time (it still passes `i3 -C`, which
does not fully parse bound commands). The fix is to wrap the **entire** command in one i3
double-quoted string — i3 treats commas inside double quotes as literal — and use inner
single quotes for the `'Start: '` prompt so `sh` keeps its trailing space:

```
bindsym $mod+d exec --no-startup-id "rofi -modi drun -show drun -display-drun 'Start: ' -drun-match-fields name,generic,keywords -show-icons -theme arthur"
```

## Display brightness

The old XFCE-panel brightness widget is replaced by **`brightnessctl`** bound to the laptop's
brightness keys. brightnessctl talks to systemd-logind (and ships a udev fallback), so it needs
**no root** to change the backlight in the active session. It drives the one backlight device
here, `intel_backlight` (`/sys/class/backlight/`).

The brightness keys are bound via the **`i3-osd`** helper, which changes the brightness *and*
shows an on-screen display (see "Volume / brightness OSD" below):

```
bindsym XF86MonBrightnessUp   exec --no-startup-id i3-osd brightness-up
bindsym XF86MonBrightnessDown exec --no-startup-id i3-osd brightness-down
```

Handy CLI: `brightnessctl` (show current), `brightnessctl set 50%`, `set 5%+`, `set 5%-`.

Note: `xbacklight` was **not** chosen — it relies on a RandR backlight property that the Intel
driver typically does not expose, so it tends to fail on this hardware; brightnessctl uses the
sysfs/logind path instead. If the `XF86MonBrightness*` keys don't trigger, check what your keys
emit with `xev` (they may produce different keysyms) and adjust the bindings.

## Volume / brightness OSD

Pressing the volume or brightness keys pops up an **on-screen display** — a deadd
notification with a **progress bar** — instead of silently changing the level. It's
driven by `~/bin/i3-osd` (tracked as `bin/i3-osd`, symlinked by `install.sh`), bound to
the `XF86Audio*` / `XF86MonBrightness*` keys in the i3 config:

```
bindsym XF86AudioRaiseVolume  exec --no-startup-id i3-osd volume-up
bindsym XF86AudioLowerVolume  exec --no-startup-id i3-osd volume-down
bindsym XF86AudioMute         exec --no-startup-id i3-osd volume-mute
bindsym XF86MonBrightnessUp   exec --no-startup-id i3-osd brightness-up
bindsym XF86MonBrightnessDown exec --no-startup-id i3-osd brightness-down
```

**Fine control.** The step size is `i3-osd`'s optional second argument (default 5%). The
config binds the **`Shift+`** variants of the raise/lower keys to a 1% step for both
volume and brightness, for precise adjustment:

```
bindsym Shift+XF86AudioRaiseVolume   exec --no-startup-id i3-osd volume-up 1
bindsym Shift+XF86AudioLowerVolume   exec --no-startup-id i3-osd volume-down 1
bindsym Shift+XF86MonBrightnessUp    exec --no-startup-id i3-osd brightness-up 1
bindsym Shift+XF86MonBrightnessDown  exec --no-startup-id i3-osd brightness-down 1
```

`i3-osd` first performs the change (`pactl` for volume — capped at 100%, unmutes on
raise/lower; `brightnessctl` for backlight), then reads back the resulting level and
fires the notification. How it behaves like a real OSD:

- **One popup that updates in place.** `notify-send -p` prints the id deadd assigns; the
  script stashes it (in `$XDG_RUNTIME_DIR/i3-osd.id`) and passes it back with `-r` next
  time, so deadd *replaces* the previous notification rather than stacking a stream of
  them. Volume and brightness share the one id, so only ever one OSD is on screen.
- **Progress bar.** `-h int:value:<pct>` — deadd renders the `value` hint as a
  percentage bar (it also accepts `has-percentage`).
- **No history clutter.** `-h boolean:transient:true` marks them transient, so they show
  as pop-ups but don't accumulate in the notification center.
- **Clean look.** `-a ""` (empty app-name) drops the "notify-send" label; each OSD shows
  just an icon (speaker level / muted / sun), a title, the percentage, and the bar. Short
  `-t 1500` timeout.

Mic-mute (`XF86AudioMicMute`) has no OSD — there's no meaningful level to show — so it
just toggles `pactl set-source-mute` directly.

## Follow-ups / ideas

- Version-control `~/.xscreensaver` once locking preferences are tuned.
- Extend `polybar-detail` to more modules if useful (e.g. wifi → IP/SSID/signal, disk →
  per-mount usage).

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
- **2026-09-29** — Dropped the Toggl integration entirely (no longer used): removed the
  `$mod+grave` binding, `git rm bin/i3-toggl-select`, removed its `~/bin` symlink, and
  cleaned up the docs.
- **2026-09-29** — Keyboard (Caps→Ctrl): replaced the `i3-setup-keyboard` watch-loop
  script with the native `localectl set-x11-keymap gb pc105 "" ctrl:nocaps` (Xorg applies
  it to hotplugged keyboards via InputClass; no `inotify-tools`/background process needed).
  Applied to the live session with `setxkbmap`, added a `configure_keyboard` step to
  install.sh, and `git rm`'d the script + `~/bin` symlink. (`inotifywait` wasn't even
  installed, so the old loop was already non-functional here.)
- **2026-09-29** — Monitor layout: installed `arandr` (graphical xrandr front-end; pulls in
  `xrandr`) + `autorandr` for persistent, per-monitor-set layout profiles. Arranged the two
  displays with arandr and saved profile `home` (`autorandr --save home`). Added both to
  install.sh and an `exec_always autorandr --change` line to the i3 config so the layout is
  reapplied on start/hotplug. Profiles are machine-specific (EDID-keyed) so left out of
  version control; documented in a new "Monitor layout" section.
- **2026-09-29** — Made ARandR findable by "Display" in the rofi launcher. Added a
  version-controlled user desktop override (`dotfiles/applications/arandr.desktop`, symlinked
  into `~/.local/share/applications`) with `Keywords=Display;Monitor;Screen;Layout;…`, and
  fixed the `$mod+d` `-drun-match-fields` value from the invalid `"Name#Generic"` to
  `name,generic,keywords` so rofi searches the keyword field. install.sh now also symlinks
  `dotfiles/applications/*.desktop`.
- **2026-09-29** — Fixed `$mod+d` failing at press time (`Expected one of these tokens…`).
  Cause: the commas in `-drun-match-fields name,generic,keywords` — i3 treats `,` as a
  command separator, so it tried to parse `generic`/`keywords` as commands. (`i3 -C` passed
  because it doesn't fully parse bound commands.) Fix: wrapped the whole rofi command in one
  i3 double-quoted string (commas inside double quotes are literal) with inner single quotes
  around `'Start: '` for sh. Verified the parse via `i3-msg` before applying; reloaded OK.
- **2026-09-29** — Automated `i3-fix-workspace-placement.py` (re-home workspaces 20-29 onto
  the external monitor) via an autorandr global `postswitch` hook scoped to the `home` profile
  (`dotfiles/autorandr/postswitch`, symlinked; install.sh updated). **Fixed the script for
  this machine:** the external output is `DP-2-3` here, not the old machine's `DP-3` — the
  hardcoded name meant the script silently no-op'd. Hoisted both output names to variables at
  the top and corrected the shebang to `/usr/bin/env python3`. Confirmed the hotplug chain
  (udev → `autorandr.service` → `autorandr --batch --change` → postswitch) and that the hook
  fires on a real switch (`autorandr --change --force`). Left to verify by a physical replug:
  that the `--batch` (system-service) environment lets the script reach i3.
- **2026-09-29** — Debugged monitor hotplug after a real unplug/replug left the external
  display stuck black. Findings: (1) X *does* detect MST hotplug here (watched
  connected↔disconnected via `xrandr`), so detection was never the problem; (2) the batch
  service reaches the session (`Running autorandr as aburgess for display :0`); (3) the real
  gap was **no laptop-only profile** — autorandr only switches to a matching saved profile, so
  unplug matched nothing and i3 kept the two-monitor layout, and with no profile transition the
  DP link was never re-driven → blank on replug. Fix: created a `mobile` (laptop-only) profile
  (`eDP-1` primary at 0x0, `DP-2-3` off; fingerprint = eDP-1 EDID only), verified both
  directions apply (`autorandr --load … --force`) and that the `home` transition re-runs the
  placement hook. Recovered the live blank screen with an off/on modeset. Documented recovery
  commands and the two-profile requirement. Physical unplug/replug end-to-end test still to be
  run by the user.
- **2026-09-29** — Physical unplug/replug tested end-to-end: **works in both directions**.
  Unplug → both screens blink, laptop returns, i3 moves all workspaces to `eDP-1`. Replug →
  blink, both return, workspaces 20-29 auto-move back to the external. Corrected two mistaken
  claims from earlier debugging: (1) `xrandr` reporting a connector as connected+moded does
  NOT mean the link is live — the panel can be black while xrandr looks healthy; (2)
  `autorandr --change --force` did **not** recover a stuck panel — only an explicit output
  off→on modeset does (the automatic path gets this because `mobile` disables `DP-2-3` before
  `home` re-enables it). Updated the recovery docs accordingly and removed the temporary
  `~/bin/i3-monitor-hotplug-test` watcher.
- **2026-09-29** — Added display brightness control: `brightnessctl` (chosen over `xbacklight`,
  which relies on a RandR backlight prop Intel doesn't expose, and over `light`). No root needed
  (logind + udev). Bound `XF86MonBrightnessUp/Down` to `brightnessctl set 5%+/-`; added the
  package to install.sh and a "Display brightness" doc section. Backlight device:
  `intel_backlight`.
- **2026-09-29** — Switched the status bar from i3bar/i3status to **polybar**. Added a
  starter `dotfiles/polybar/config.ini` (i3 workspaces, window title, backlight, volume, memory,
  cpu, wifi, battery, clock, tray; plain-text labels on monospace) and `launch.sh` (one bar per
  connected monitor, tray on primary). Replaced the i3 `bar {}` block with `exec_always ...
  launch.sh` (old block kept commented as fallback). Added polybar to install.sh + symlinks.
  Baked in machine-specific names: battery BAT0/AC, wifi wlp0s20f3, backlight intel_backlight.
- **2026-09-29** — Fixed the clock: machine shipped on `US/Eastern` (EDT) so `date`/i3bar
  showed the wrong local time (UTC/NTP were correct). `sudo timedatectl set-timezone
  Europe/London`. Added a `configure_timezone` step to install.sh and a "Timezone" doc section.
- **2026-09-29** — Polybar: replaced the plain-text status labels with **glyph icons** from
  Font Awesome 6 Free (Solid). Added `font-1 = Font Awesome 6 Free:style=Solid` and switched
  backlight (sun), volume (level-ramping speaker / crossed-out muted), disk (hard-drive), memory,
  cpu (microchip), wifi, and clock (calendar) to icons; battery now uses a capacity ramp with a
  charging bolt. Added `fontawesome-6-free-fonts` to install.sh. Glyphs stored as literal UTF-8,
  injected from ASCII placeholders via `perl -CSD` to guarantee exact codepoints.
- **2026-09-29** — Added a **power menu**: `bin/i3-power-menu` (rofi: Lock/Logout/Suspend/Reboot/
  Shutdown via systemd-logind, no sudo). Reachable from a new polybar power glyph (`custom/text`,
  click-left) and the `$mod+Escape` keybinding. New doc section "Power menu (i3-power-menu)".
- **2026-09-30** — Added a **compositor (picom)** so translucency/shadows/rounded corners work
  under i3 (without one, RGBA areas render black). Config `dotfiles/picom/picom.conf` (glx backend,
  drop shadows, 12px rounded corners, `dual_kawase` blur, short fades; docks excluded). Autostarted
  from the i3 config with a `pkill -x picom` guard so `exec_always` doesn't stack instances on
  restart. Added `picom` to install.sh + symlink and a new "Compositor (picom)" doc section. Primary
  motivation: make the (in-progress) deadd notification cards render as frosted-glass panels. Fixed
  a deprecated `_GTK_FRAME_EXTENTS@:c` → `_GTK_FRAME_EXTENTS@` selector.
- **2026-09-30** — Installed **deadd** (notification daemon) permanently and documented it in a
  new "Notifications (deadd)" section. Not in Fedora's repos, so it's built with Haskell `stack`
  from a personal fork whose `master` carries the gi-glib 2.0.30 build fix (`unixSignalAdd` →
  `installHandler`+`idleAdd`; committed to the fork and pushed). Listed the dnf build deps
  (`stack`, `gtk3-devel`, `cairo-devel`, `pango-devel`, `gobject-introspection-devel`,
  `libX11-devel`, `libXrender-devel`, `libconfig-devel`) and the `make` build (→ `.out/…`). The
  ~104 MB binary is too big to version-control, so `install.sh` copies it into `~/bin` (helper
  `install_deadd_binary`, `DEADD_BUILD_BIN`-overridable; skips with a note if the build output
  isn't present). Autostart added to the i3 config (`exec_always` with a `pkill -x deadd-notificat`
  guard, like picom). Config/theme (`dotfiles/deadd/deadd.{yml,css}`) symlinked into
  `~/.config/deadd/` by `install.sh`.
- **2026-09-30** — Added a **volume/brightness OSD** (`bin/i3-osd`): the `XF86Audio*` and
  `XF86MonBrightness*` keys now change the level *and* show a deadd notification with a progress
  bar. Repeated presses update one popup in place (capture the id via `notify-send -p`, replay it
  with `-r`; id stashed in `$XDG_RUNTIME_DIR`), the bar comes from the `value` hint, `transient`
  keeps them out of the center, and `-a ""` drops the app-name label. Volume capped at 100% and
  unmutes on adjust; mic-mute left as a plain toggle (no level to show). Replaced the old direct
  `pactl`/`brightnessctl` bindings and dropped the now-unused `$refresh_i3status` (leftover from
  i3status; polybar self-updates). New "Volume / brightness OSD" doc section.
- **2026-09-30** — Brightened deadd's **symbolic notification icons** (the OSD sun/speaker looked
  muted grey). Root cause: deadd ignores GNOME's `prefer-dark` preference and, under the light
  Adwaita theme, renders symbolic icons in a dark-grey foreground; CSS `color` has no effect because
  deadd loads icons via `imageSetFromIconName`. Fixed by launching deadd with `GTK_THEME=Adwaita:dark`
  in the autostart, which flips symbolic icons to bright near-white (full-colour app icons unaffected).
  Documented the mechanism in the deadd section and added a note in `deadd.css`.
- **2026-09-30** — Added **click-to-details** on polybar (`bin/polybar-detail`): left-clicking the
  cpu / memory / battery glyphs fires a deadd notification with the breakdown that doesn't fit in
  the bar — load averages + top CPU processes, memory usage + top RAM processes, and battery
  charge/state/draw/time-remaining (via `upower`). Reuses one popup per repeated click (`-p`/`-r`)
  and marks them `transient`. Wired with `%{A1:...:}` action tags in each module's `format` rather
  than a module-level `click-left`, which (verified) doesn't fire on internal modules in polybar
  3.7.2. Raised deadd's `max-lines-in-body` 4 → 10 so the ~8-line breakdowns aren't truncated. New
  "Click-to-details" note in the polybar section.
- **2026-09-30** — Restricted the polybar **power glyph** (lock/suspend/logout menu) and the system
  tray to the **primary (laptop) display** only. polybar can't conditionally include a module via
  an env var in a `modules-*` list (it reads `${env:...}` there literally), so the difference is a
  separate `[bar/secondary]` that `inherit`s `bar/main` and overrides `modules-right` to drop
  `power`. `launch.sh` runs `polybar main` on the primary output and `polybar secondary` elsewhere.
  Verified: primary bar loads 10 modules (power + tray), secondary loads 9 (ends at the clock).
- **2026-09-30** — Added a **notification-center bell** glyph to polybar, next to the power glyph
  and (like it) on the primary display only. It's a `custom/text` module whose `click-left` sends
  `pkill -SIGUSR1 -x deadd-notificat`, toggling the deadd center open/closed. Dropped from
  `[bar/secondary]`'s `modules-right` alongside `power`, so it too is primary-display only.
- **2026-09-30** — Stopped the deadd **notification center overlapping polybar**. The center is
  drawn full screen height, so its bottom edge previously sat under the bottom-docked bar. Set
  deadd's `margin-bottom: 32` (≈ polybar's 24pt @ 96dpi height), which reserves bottom-bar space so
  the center is drawn that much shorter and ends flush above the bar. Verified on both monitors.
- **2026-09-30** — Fixed the notification center **overlapping polybar on the primary monitor after
  it had been opened on the (taller) secondary one first**. Root cause: deadd sized the center with
  `windowSetDefaultSize`, which GTK only honours on a window's first map, so the height was locked
  to whichever monitor opened it first and never adapted (our monitors are 1080 vs 1200 tall).
  Added a second commit to the deadd fork that also calls `windowResize` in
  `setNotificationCenterPosition`, forcing a resize on every show. Rebuilt and reinstalled the
  binary; verified the center now resizes correctly on both monitors in either open order.
- **2026-09-30** — Ported the old machine's **inactive-window dimming** into picom. Added
  `inactive-dim = 0.5` plus a `focus-exclude` list (docks, desktop, notifications, deadd center,
  rofi, i3 frames, xscreensaver, unnamed transients) so non-focused windows dim to half brightness
  while polybar and deadd pop-ups stay bright. Replaces the old standalone `window-dimmer` script
  (which ran a second compositor for compton's `--inactive-dim`); now folded into the running picom.
  Verified: focused→unfocused brightness ratio measured exactly 0.50; polybar/popups unaffected.
- **2026-09-30** — Added **fine (1%) volume & brightness control**. `i3-osd` now takes an optional
  step as its second argument (default 5%); bound the `Shift+` variants of the volume and brightness
  raise/lower keys to a 1% step. Ports the old machine's fine-volume keys and extends the same idea
  to brightness. Verified ±1% vs the default ±5%.
- **2026-09-30** — **Pinned the numbered workspaces (1-10) to the primary output** so they always
  open on the laptop panel. Added `workspace $wsN output primary` for each; used i3's `primary`
  keyword instead of a hardcoded `eDP-1` to stay machine-independent. Ports the old machine's
  workspace-to-output pinning. Verified a fresh numbered workspace opens on the laptop even when the
  external monitor has focus.
- **2026-09-30** — **Silenced the PC-speaker beep** at the source by blacklisting the `pcspkr`
  kernel module (`dotfiles/modprobe.d/nobeep.conf` → `/etc/modprobe.d/nobeep.conf`: `blacklist` +
  `install … /bin/true` for `pcspkr` and `snd_pcsp`). This kills the beep system-wide (X *and* the
  TTY) permanently, unlike the old machine's per-session `xset -b`. `install.sh` gained
  `disable_pcspkr_beep` (sudo-copies the file, then `modprobe -r pcspkr` so it stops without a
  reboot). Verified `pcspkr` unloaded and the file installed root-owned. New "Silencing the
  PC-speaker beep" doc section.
- **2026-09-30** — Added a **desktop wallpaper** (previously blank grey root window). New
  `bin/i3-wallpaper` paints a random image per monitor from `~/Pictures/Wallpapers` with
  `feh --bg-fill --randomize` (one image per monitor; `--bg-fill` fills without distortion).
  Kept deliberately simple — in a tiler the wallpaper only shows briefly before a window
  covers it. Wired via `exec_always` (re-rolls on i3 start/restart) and the autorandr
  `postswitch` hook (repaints per-monitor on dock/undock). Added `feh` to `install.sh`. Ports
  the old machine's feh/`.fehbg` mechanism. New "Desktop wallpaper (feh)" doc section.
