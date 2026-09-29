#!/usr/bin/env bash
#
# Launch polybar: one bar per connected monitor, tray only on the primary.
# Called from the i3 config (exec_always) so it re-runs on i3 restart, and it can
# be re-run any time to respawn bars after a monitor change.

# Terminate any running instances cleanly, then wait for them to exit.
polybar-msg cmd quit >/dev/null 2>&1 || killall -q polybar || true
for _ in 1 2 3 4 5; do
    pgrep -x polybar >/dev/null || break
    sleep 0.2
done

primary="$(xrandr --query | awk '/ connected primary/ {print $1}')"

# One bar per connected monitor. Only the primary carries the system tray.
for m in $(polybar --list-monitors | cut -d: -f1); do
    if [ "$m" = "$primary" ]; then
        TRAY_POSITION=right
    else
        TRAY_POSITION=none
    fi
    MONITOR="$m" TRAY_POSITION="$TRAY_POSITION" polybar --reload main >>"/tmp/polybar-$m.log" 2>&1 &
done
