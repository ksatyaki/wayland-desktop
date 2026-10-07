#!/bin/sh
# Super+P: toggle between the site layout in hyprland.lua (laptop / home / office) and a single external monitor.
# Single mode picks the external with the highest resolution, then the highest refresh rate (capped, see max_hz), runs it at that mode at 0x0
# and switches every other output off, the laptop panel included. The pick goes to $XDG_RUNTIME_DIR/hypr-single-monitor
# (line 1: "<output> <WxH@Hz>", then one output name per line to disable); hyprland.lua reads that file at (re)load, so a
# plain `hyprctl reload` applies whichever layout the file says. The workspace -> monitor map from before single mode is
# kept next to it and restored on the way back.
#   single-monitor.sh           toggle
#   single-monitor.sh refresh   called from hyprland.lua on monitor hotplug: in single mode re-pick (a bigger monitor
#                               takes over, a vanished one is dropped); in layout mode do nothing
set -eu
flag="${XDG_RUNTIME_DIR:-/tmp}/hypr-single-monitor"
# refresh rates above this are ignored: the AOC advertises 180 Hz over the dock's DisplayPort but shows no picture there
max_hz=${SINGLE_MONITOR_MAX_HZ:-144}

# best external and the outputs to switch off; prints nothing when no external monitor is connected
pick() {
    hyprctl -j monitors all | jq -r --argjson max "$max_hz" '
        map(select(.name != "eDP-1")) as $ext
        | if ($ext | length) == 0 then empty else
            ([ $ext[] | . as $m | .availableModes[]
               | capture("^(?<w>[0-9]+)x(?<h>[0-9]+)@(?<r>[0-9.]+)")
               | { name: $m.name, w: (.w | tonumber), h: (.h | tonumber), r: (.r | tonumber) }
               | select(.r <= $max + 0.5) ]
             | max_by([.w * .h, .r])) as $best
            | "\($best.name) \($best.w)x\($best.h)@\(($best.r + 0.5) | floor)",
              (.[] | select(.name != $best.name) | .name)
          end'
}

notify() { command -v notify-send >/dev/null 2>&1 && notify-send -a Hyprland "Monitors" "$1" || true; }

# apply the layout the flag file (or its absence) describes, then put the bar and the workspaces straight
apply() {
    hyprctl reload >/dev/null
    sleep 2   # let the outputs come back before touching the bar and the workspaces
    # waybar keeps one bar per output; it has been seen to lose or drop its bars when outputs go away and come back,
    # so make it rebuild them (SIGUSR2 = reload), or start it again if it died
    if pgrep -x waybar >/dev/null; then pkill -USR2 -x waybar
    else setsid waybar -c "$HOME/.config/waybar/config-hyprland.jsonc" >/dev/null 2>&1 & fi
    # workspaces that were herded onto the single monitor go back to where they were
    if [ -s "$flag.workspaces" ] && [ ! -e "$flag" ]; then
        while read -r ws mon; do
            if hyprctl -j monitors | jq -e --arg m "$mon" 'any(.name == $m)' >/dev/null 2>&1; then
                hyprctl dispatch moveworkspacetomonitor "$ws" "$mon" >/dev/null || true
            fi
        done < "$flag.workspaces"
        rm -f "$flag.workspaces"
    fi
}

case "${1:-toggle}" in
refresh)
    [ -e "$flag" ] || exit 0
    new=$(pick)
    if [ -z "$new" ]; then
        rm -f "$flag"; apply; notify "No external monitor left: back to the site layout"
    elif [ "$new" != "$(cat "$flag")" ]; then
        printf '%s\n' "$new" > "$flag"; apply
    fi ;;
toggle)
    if [ -e "$flag" ]; then
        rm -f "$flag"; apply; notify "Site layout"
    else
        new=$(pick)
        if [ -z "$new" ]; then notify "No external monitor connected"; exit 0; fi
        hyprctl -j workspaces | jq -r '.[] | select(.id > 0) | "\(.id) \(.monitor)"' > "$flag.workspaces"
        printf '%s\n' "$new" > "$flag"; apply
        notify "Single monitor: $(printf '%s\n' "$new" | head -n 1)"
    fi ;;
*)  echo "usage: $0 [toggle|refresh]" >&2; exit 2 ;;
esac
