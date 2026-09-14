#!/bin/sh
# Installs sddm-astronaut-theme with the DOOM preset and makes it the SDDM theme. Run with sudo.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
DST=/usr/share/sddm/themes/sddm-astronaut-theme
rm -rf "$DST"
cp -r "$HERE/sddm-astronaut-theme" "$DST"
mkdir -p /usr/share/fonts/sddm-astronaut-theme
cp "$DST"/Fonts/*.ttf "$DST"/Fonts/*.otf /usr/share/fonts/sddm-astronaut-theme/
fc-cache -f >/dev/null
mkdir -p /etc/sddm.conf.d
cp "$HERE"/sddm.conf.d/10-theme.conf "$HERE"/sddm.conf.d/20-users.conf /etc/sddm.conf.d/
echo "SDDM theme installed: $DST (preset $DST/Themes/doom.conf). Takes effect at the next logout."
