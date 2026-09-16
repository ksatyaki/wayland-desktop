#!/bin/sh
# Installs one of the DOOM login themes and makes it the SDDM theme. Run with sudo.
#   install-sddm-theme.sh [eternal|dark-ages]     default: eternal
# eternal   = sddm-astronaut-theme with the DOOM Eternal preset (Themes/doom.conf)
# dark-ages = sddm-dark-ages-theme (DOOM: The Dark Ages look)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
case "${1:-eternal}" in
    eternal)   THEME=sddm-astronaut-theme;;
    dark-ages) THEME=sddm-dark-ages-theme;;
    *) echo "usage: $0 [eternal|dark-ages]" >&2; exit 2;;
esac
DST=/usr/share/sddm/themes/$THEME
rm -rf "$DST"
cp -r "$HERE/$THEME" "$DST"
# the greeter runs as the sddm user, so the fonts must be system-wide (the Dark Ages theme also loads its own from the theme dir)
mkdir -p "/usr/share/fonts/$THEME"
find "$DST/Fonts" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -exec cp {} "/usr/share/fonts/$THEME/" \;
fc-cache -f >/dev/null
mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=%s\n' "$THEME" > /etc/sddm.conf.d/10-theme.conf
cp "$HERE"/sddm.conf.d/20-users.conf /etc/sddm.conf.d/
echo "SDDM theme installed: $DST ($THEME). Takes effect at the next logout."
