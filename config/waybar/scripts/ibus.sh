#!/bin/sh
# Current IBus engine as waybar JSON, updated on IBus's GlobalEngineChanged signal (no polling).
# The xkb layout (us/se) is Hyprland's and shown by hyprland/language; this shows the input method on top of
# it: "A" for plain xkb engines, the script of the language for the rest (அ for Tamil).
# `ibus.sh toggle` cycles through the engines picked in ibus-setup (for on-click).
set -u

label() {
    case "$1" in
        *:ta:*) printf 'அ' ;;
        xkb:*)  printf 'A' ;;
        *)      printf '%s' "${1#*:}" | cut -d: -f1 ;;
    esac
}

emit() {
    printf '{"text":"%s","tooltip":"IBus: %s","class":"%s"}\n' "$(label "$1")" "$1" "${1%%:*}"
}

if [ "${1:-}" = toggle ]; then
    cur=$(ibus engine)
    # preload-engines: ['xkb:us::eng', 'm17n:ta:phonetic'] -> one per line
    set -- $(gsettings get org.freedesktop.ibus.general preload-engines | tr -d "[]'," )
    next=$1
    while [ $# -gt 0 ]; do
        if [ "$1" = "$cur" ]; then next=${2:-$next}; break; fi
        shift
    done
    exec ibus engine "$next"
fi

while :; do
    addr=$(ibus address 2>/dev/null) || { emit ""; sleep 2; continue; }
    emit "$(ibus engine 2>/dev/null)"
    # exits when the daemon goes away; the loop then reconnects to the new one
    gdbus monitor --address "$addr" --dest org.freedesktop.IBus --object-path /org/freedesktop/IBus 2>/dev/null |
    while IFS= read -r line; do
        case "$line" in
            *GlobalEngineChanged*) emit "$(printf '%s' "$line" | sed -n "s/.*('\([^']*\)',).*/\1/p")" ;;
        esac
    done
    sleep 1
done
