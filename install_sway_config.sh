#!/bin/sh
# Installs the Sway desktop from this repo. See install_common.sh for options (--packages, --system).
. "$(dirname "$0")/install_common.sh"

if [ "$WANT_PACKAGES" = 1 ]; then
    install_packages "sway swaylock swayidle swaybg kanshi xdg-desktop-portal-wlr"
fi

install_shared
echo "Sway config:"
for d in sway kanshi swaylock; do put_config "$d"; done
if [ "$WANT_SYSTEM" = 1 ]; then
    echo "Session file (sudo): /usr/local/share/wayland-sessions/sway-nvidia.desktop"
    sudo mkdir -p /usr/local/share/wayland-sessions
    sudo cp "$REPO/system/wayland-sessions/sway-nvidia.desktop" /usr/local/share/wayland-sessions/
    sudo usermod -aG video "$USER"
    install_sddm_theme
fi
note_fonts
cat <<'MSG'
Done. Log out and pick "Sway (NVIDIA)" in SDDM. Re-run with --system for the session file, video group and DOOM login theme, --packages to install packages.
MSG
