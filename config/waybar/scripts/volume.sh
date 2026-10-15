#!/bin/bash
# Default-sink volume for the waybar pulseaudio module's scroll events.
#
#   volume.sh scroll 5%+|5%-     one step to the next/previous multiple of 5, at most once per $SCROLL_MS
#
# Waybar's built-in handling takes one scroll-step per event, and the touchpad delivers one event per
# frame, dozens per swipe, so a swipe used to run through much of the range. Setting on-scroll-up/down
# on the module switches the built-in handling off; this script does the same as brightness.sh "scroll":
# "5%+" goes to the next multiple of 5 (21 -> 25, 25 -> 30), "5%-" to the previous one (28 -> 25,
# 25 -> 20), and events within $SCROLL_MS of the last step that went through are dropped. The module
# redraws itself from the PipeWire event, so nothing has to signal waybar. The Fn keys keep plain wpctl.
set -u

SCROLL_MS=200                               # minimum time between two scroll steps
SINK=@DEFAULT_AUDIO_SINK@
STATE="${XDG_RUNTIME_DIR:-/tmp}/volume"
mkdir -p "$STATE"

# at most one scroll step per $SCROLL_MS; the lock serialises the scripts that waybar spawns for one
# swipe, so exactly one of them takes the step and the rest see it and exit
throttle() {
    local f="$STATE/step" now last
    exec 7>"$STATE/step.lock"; flock 7
    now=$(( ${EPOCHREALTIME/./} / 1000 )); last=$(cat "$f" 2>/dev/null); last=${last:-0}
    [ $(( now - last )) -ge $SCROLL_MS ] || return 1
    echo "$now" > "$f"
}

adjust() {   # <5%+|5%->
    local cur new n
    cur=$(wpctl get-volume "$SINK" 2>/dev/null | awk '{ printf "%d", $2 * 100 + 0.5 }')
    cur=${cur:-50}
    case $1 in
        *%+) n=${1%\%+}; new=$(( (cur / n + 1) * n ));;             # next multiple of n above cur
        *%-) n=${1%\%-}; new=$(( ((cur + n - 1) / n - 1) * n ));;   # previous multiple of n below cur
        *)   echo "usage: volume.sh scroll 5%+|5%-" >&2; exit 2;;
    esac
    (( new < 0 )) && new=0
    (( new > 100 )) && new=100
    wpctl set-volume -l 1.0 "$SINK" "${new}%"
}

case ${1:-} in
    scroll) throttle && adjust "${2:?usage: volume.sh scroll 5%+|5%-}";;
    *)      echo "usage: volume.sh scroll 5%+|5%-" >&2; exit 2;;
esac
