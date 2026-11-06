#!/bin/bash
# Keep the mouse inside fullscreen Proton games on a multi-monitor desktop.
#
# Why: Wine confines the pointer to a fullscreen window by itself only when that window covers the whole desktop, i.e.
# with a single monitor. With more, edge scrolling in a strategy game (Age of Empires II DE) runs the pointer off onto
# the neighbouring output. Wine's "Automatically capture the mouse in full-screen windows" setting (winecfg, Graphics
# tab; registry HKCU\Software\Wine\X11 Driver, GrabFullscreen=Y) makes it confine on any monitor. Xwayland turns that
# X11 grab into a Wayland pointer constraint, which Hyprland and Sway both honour; neither compositor has a setting of
# its own for this. The pointer is released again when the game loses focus (workspace switch, Super+Tab).
#
# The value lives in each game's Wine prefix and is read when the game starts, so run this again after installing a game.
#
# Usage: tools/proton-grab-fullscreen.sh [--remove] [appid ...]    (default: every Proton prefix in every Steam library)
set -u
REMOVE=0; [ "${1:-}" = "--remove" ] && { REMOVE=1; shift; }
KEY='HKCU\Software\Wine\X11 Driver'
STEAM=${XDG_DATA_HOME:-$HOME/.local/share}/Steam

command -v protontricks >/dev/null 2>&1 || { echo "protontricks is not installed." >&2; exit 1; }

# true when the prefix's user.reg already has GrabFullscreen=Y under the X11 Driver key
has_grab() {
  awk '/^\[/ { s = ($0 ~ /^\[Software\\\\Wine\\\\X11 Driver\]/) }
       s && /^"GrabFullscreen"="Y"/ { f = 1 }
       END { exit !f }' "$1"
}

mapfile -t LIBS < <(sed -n 's/^[[:space:]]*"path"[[:space:]]*"\(.*\)"$/\1/p' "$STEAM/steamapps/libraryfolders.vdf")
for lib in "${LIBS[@]}"; do
  for reg in "$lib"/steamapps/compatdata/*/pfx/user.reg; do
    [ -f "$reg" ] || continue
    id=${reg%/pfx/user.reg}; id=${id##*/}
    [ $# -gt 0 ] && [[ " $* " != *" $id "* ]] && continue
    name=$(sed -n 's/^[[:space:]]*"name"[[:space:]]*"\(.*\)"$/\1/p' "$lib/steamapps/appmanifest_$id.acf" 2>/dev/null)
    [ -n "$name" ] || continue   # no manifest next to the prefix: a non-Steam shortcut's or an uninstalled game's leftover
    [[ $name == Proton\ * ]] && continue   # Proton builds keep a prefix of their own; protontricks refuses those
    if [ $REMOVE = 1 ]; then
      has_grab "$reg" || { echo "not set   $id  $name"; continue; }
      cmd="wine reg delete \"$KEY\" /v GrabFullscreen /f"
    else
      has_grab "$reg" && { echo "already   $id  $name"; continue; }
      cmd="wine reg add \"$KEY\" /v GrabFullscreen /d Y /f"
    fi
    if protontricks -c "$cmd" "$id" >/dev/null 2>&1; then echo "done      $id  $name"
    else echo "FAILED    $id  $name" >&2; fi
  done
done
