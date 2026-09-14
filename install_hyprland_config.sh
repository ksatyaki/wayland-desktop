#!/bin/sh
# Installs the Hyprland desktop from this repo. See install_common.sh for options (--packages, --system).
. "$(dirname "$0")/install_common.sh"

if [ "$WANT_PACKAGES" = 1 ]; then
    sudo dnf copr enable -y lionheartp/Hyprland
    install_packages "hyprland hyprlock hypridle hyprpolkitagent hyprshot hyprshutdown hyprland-guiutils xdg-desktop-portal-hyprland"
fi

install_shared
echo "Hyprland config:"
put_config hypr
[ "$WANT_SYSTEM" = 1 ] && install_sddm_theme
note_fonts
cat <<'MSG'
Done. Log out and pick "Hyprland" in SDDM. Re-run with --system to install the DOOM login theme, --packages to install packages.
MSG
