#!/usr/bin/env bash
# Per-monitor brightness, for the waybar module and the XF86MonBrightness keys.
#
#   brightness.sh status <output>                waybar JSON for that output's bar
#   brightness.sh set    <output> 5%+|5%-|50%    <output> may be "focused"
#
# The laptop panel goes through /sys/class/backlight (brightnessctl); external
# monitors go over DDC/CI (ddcutil), which needs i2c access -- see docs/bar.md.
# A DDC round trip costs ~0.3 s, so the value shown in the bar is cached in
# $XDG_RUNTIME_DIR and rapid scrolls are coalesced into a single monitor write.
set -u

VCP=10                                      # DDC/CI "luminance"
SIG=8                                       # waybar signal for custom/brightness
TTL=300                                     # re-read the hardware after this many seconds
DDC=(--sleep-multiplier .3 --noverify)
STATE="${XDG_RUNTIME_DIR:-/tmp}/brightness"
mkdir -p "$STATE"

# ---------------------------------------------------------------- compositor
outputs() {   # [{name, serial, focused}] from whichever compositor is running
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
        hyprctl monitors -j 2>/dev/null | jq -c '[.[]|{name, serial, focused, desc:.description}]'
    elif [ -n "${SWAYSOCK:-}" ] && command -v swaymsg >/dev/null 2>&1; then
        swaymsg -t get_outputs -r 2>/dev/null | jq -c '[.[]|{name, serial, focused, desc:"\(.make) \(.model)"}]'
    else
        echo '[]'
    fi
}
field() { outputs | jq -r --arg n "$1" --arg f "$2" '.[]|select(.name==$n)|.[$f] // ""'; }

# ---------------------------------------------------------------- backend per output
# "sys <device>" for a panel under /sys/class/backlight, "ddc <i2c bus>" for a
# monitor that answers DDC/CI, "none" for one that does neither (the module hides).
detect_backend() {   # <output> <serial>
    case "$1" in
        eDP-*|LVDS-*|DSI-*)
            for d in /sys/class/backlight/*; do
                [ -e "$d" ] || continue
                case "${d##*/}" in ddcci*) continue;; esac
                echo "sys ${d##*/}"; return
            done;;
    esac
    command -v ddcutil >/dev/null 2>&1 || { echo none; return; }
    # ddcutil detect --terse lists, per display, the i2c bus, the DRM connector
    # (ddcutil >= 2.0) and "Mfg:Model:Serial"; match on either the connector or the serial.
    local bus
    bus=$(ddcutil detect --terse 2>/dev/null | awk -v conn="$1" -v ser="$2" '
        # one block per display, headed by an unindented line ("Display 1", "Invalid display");
        # ddcutil spells the connector "DRM_connector" and gives the serial as "Monitor: mfg:model:serial"
        # under --terse and as "Serial number:" in the EDID synopsis otherwise.
        function flush() {
            if (!found && valid && bus != "" && (drm == conn || (ser != "" && mser == ser))) { print bus; found = 1 }
            bus = ""; drm = ""; mser = ""
        }
        /^[^[:space:]]/                { flush(); valid = ($0 !~ /^Invalid/); next }
        /I2C bus:/                     { b = $0; sub(/.*i2c-/, "", b); bus = b }
        /DRM_?connector:/              { drm = $NF; sub(/^card[0-9]+-/, "", drm) }
        /^[[:space:]]*Monitor:/        { m = $0; sub(/.*Monitor:[[:space:]]*/, "", m); n = split(m, f, ":"); mser = f[n] }
        /^[[:space:]]*Serial number:/  { m = $0; sub(/.*Serial number:[[:space:]]*/, "", m); sub(/[[:space:]]+$/, "", m)
                                         if (m != "") mser = m }
        END                            { flush() }')
    [ -n "$bus" ] && echo "ddc $bus" || echo none
}

backend() {   # <output> -> sets BTYPE / BARG; cached until the output's serial changes
    local out=$1 serial cser f
    f="$STATE/$out.backend"
    serial=$(field "$out" serial); serial=${serial:--}
    if [ -r "$f" ]; then
        IFS=$'\t' read -r BTYPE BARG cser < "$f"
        if [ "$cser" = "$serial" ]; then
            [ "$BTYPE" != none ] && return
            # a monitor that did not answer may only have been missing ddcutil or the i2c group: re-probe now and then
            [ $(( $(date +%s) - $(stat -c %Y "$f") )) -lt 600 ] && return
        fi
    fi
    read -r BTYPE BARG <<<"$(detect_backend "$out" "$serial") "
    printf '%s\t%s\t%s\n' "$BTYPE" "$BARG" "$serial" > "$f"
}

# ---------------------------------------------------------------- hardware
hw_get() {   # -> 0..100, and remember the DDC value range
    case $BTYPE in
        sys) brightnessctl -m -d "$BARG" info 2>/dev/null | awk -F, '{gsub("%", "", $4); print $4}';;
        ddc) ddcutil --bus "$BARG" "${DDC[@]}" getvcp $VCP --terse 2>/dev/null |
                 awk -v f="$STATE/$OUT.ddcmax" '$1 == "VCP" && NF >= 5 { print int($4 * 100 / $5 + 0.5); print $5 > f }';;
    esac
}
hw_set() {   # <0..100>
    case $BTYPE in
        sys) brightnessctl -q -d "$BARG" set "$1%";;
        ddc) local max; max=$(cat "$STATE/$OUT.ddcmax" 2>/dev/null); max=${max:-100}
             ddcutil --bus "$BARG" "${DDC[@]}" setvcp $VCP "$(( $1 * max / 100 ))" >/dev/null 2>&1;;
    esac
}

value() {   # cached percentage, refreshed from the hardware once it goes stale
    local f="$STATE/$OUT.value" v
    if [ -r "$f" ] && [ $(( $(date +%s) - $(stat -c %Y "$f") )) -lt $TTL ]; then
        v=$(cat "$f")
    else
        v=$(hw_get); [ -n "$v" ] && echo "$v" > "$f"
    fi
    echo "${v:-}"
}
refresh() { pkill -"RTMIN+$SIG" waybar 2>/dev/null; }

# ---------------------------------------------------------------- commands
status() {
    backend "$OUT"
    # no backend: print nothing, which tells waybar to hide the module on this monitor
    [ "$BTYPE" = none ] && return
    local v; v=$(value)
    [ -n "$v" ] || return
    local kind; [ "$BTYPE" = ddc ] && kind="DDC/CI" || kind="backlight"
    jq -nc --arg t "$v%" --argjson p "$v" \
           --arg tip "$(field "$OUT" desc) ($OUT) — $kind — $v%" \
           '{text: $t, percentage: $p, tooltip: $tip, class: "brightness"}'
}

adjust() {   # <5%+|5%-|50%>
    backend "$OUT"
    [ "$BTYPE" = none ] && return
    local new cur
    cur=$(value); cur=${cur:-50}
    case $1 in
        *%+) new=$(( cur + ${1%\%+} ));;
        *%-) new=$(( cur - ${1%\%-} ));;
        *%)  new=${1%\%};;
        *)   new=$1;;
    esac
    [ "$new" -lt 1 ]   && new=1
    [ "$new" -gt 100 ] && new=100
    echo "$new" > "$STATE/$OUT.value"; refresh
    if [ "$BTYPE" = sys ]; then hw_set "$new"; return; fi
    # coalesce: the bar is already showing the new value, so only the last
    # position of a scroll burst has to reach the monitor over i2c
    echo "$new" > "$STATE/$OUT.pending"
    (
        flock -n 9 || exit 0
        while [ -s "$STATE/$OUT.pending" ]; do
            v=$(cat "$STATE/$OUT.pending"); : > "$STATE/$OUT.pending"
            hw_set "$v"
        done
    ) 9>"$STATE/$OUT.lock" &
}

cmd=${1:-status}; OUT=${2:-focused}
[ "$OUT" = focused ] && OUT=$(outputs | jq -r '.[]|select(.focused)|.name' | head -1)
[ -n "$OUT" ] || exit 0
case $cmd in
    status) status;;
    set)    adjust "${3:?usage: brightness.sh set <output> 5%+|5%-|50%}";;
    *)      echo "usage: brightness.sh status|set <output> [5%+]" >&2; exit 2;;
esac
