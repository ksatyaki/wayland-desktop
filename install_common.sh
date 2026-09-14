#!/bin/sh
# Shared part of install_hyprland_config.sh and install_sway_config.sh. Not meant to be run directly.
# Usage of the callers:  ./install_<wm>_config.sh [--packages] [--system]
#   --packages  dnf install everything the desktop needs (asks for sudo)
#   --system    also install the parts under /usr and /etc (SDDM theme, session file; asks for sudo)
set -e
REPO=$(cd "$(dirname "$0")" && pwd)
STAMP=$(date +%Y%m%d-%H%M%S)
WANT_PACKAGES=0; WANT_SYSTEM=0
for a in "$@"; do case "$a" in --packages) WANT_PACKAGES=1;; --system) WANT_SYSTEM=1;; -h|--help) sed -n 3,6p "$REPO/install_common.sh"; exit 0;; *) echo "unknown option: $a" >&2; exit 2;; esac; done

# put <repo>/config/<name> at ~/.config/<name>, keeping a timestamped backup of whatever was there
put_config() {
    src="$REPO/config/$1"; dst="$HOME/.config/$1"
    if [ -e "$dst" ]; then
        if diff -rq "$src" "$dst" >/dev/null 2>&1; then echo "  $dst (unchanged)"; return 0; fi
        mv "$dst" "$dst.bak-$STAMP"; echo "  backup: $dst.bak-$STAMP"
    fi
    mkdir -p "$(dirname "$dst")"; cp -r "$src" "$dst"; echo "  $dst"
}

install_shared() {
    echo "Shared config:"
    for d in waybar mako fuzzel qt6ct qt5ct gtk-3.0 gtk-4.0 waypaper mimeapps.list; do put_config "$d"; done
    chmod +x "$HOME/.config/waybar/scripts/perf.sh" "$HOME/.config/waybar/scripts/gpu.sh"
    if [ -e "$HOME/.zprofile" ] && ! cmp -s "$REPO/home/.zprofile" "$HOME/.zprofile"; then
        cp "$HOME/.zprofile" "$HOME/.zprofile.bak-$STAMP"; echo "  backup: ~/.zprofile.bak-$STAMP"
    fi
    cp "$REPO/home/.zprofile" "$HOME/.zprofile"; echo "  ~/.zprofile"
    mkdir -p "$HOME/.fonts/doom" "$HOME/Pictures/Wallpapers"
    cp "$REPO"/fonts/doom/*.ttf "$HOME/.fonts/doom/"; fc-cache -f >/dev/null; echo "  ~/.fonts/doom (Eternal UI)"
    cp "$REPO"/wallpapers/* "$HOME/Pictures/Wallpapers/"; echo "  ~/Pictures/Wallpapers"
    mkdir -p "$HOME/.config/sddm-doom-theme"; cp -r "$REPO/sddm/." "$HOME/.config/sddm-doom-theme/"; echo "  ~/.config/sddm-doom-theme (master copy of the login theme)"
    xdg-mime default pcmanfm-qt.desktop inode/directory 2>/dev/null || true
}

SHARED_PACKAGES="waybar fuzzel mako brightnessctl playerctl grim slurp wl-clipboard wdisplays waypaper awww \
pavucontrol nm-connection-editor blueman gnome-keyring xdg-desktop-portal-gtk \
pcmanfm-qt qt6ct qt5ct kvantum sddm sddm-themes"

install_packages() {  # $1 = extra packages for the compositor
    echo "Installing packages (sudo dnf):"
    sudo dnf install -y $SHARED_PACKAGES $1
}

install_sddm_theme() {
    echo "Login screen (sudo):"
    sudo sh "$REPO/sddm/install-sddm-theme.sh"
}

note_fonts() {
    cat <<'MSG'

Fonts to fetch yourself (not in this repo): JetBrainsMono Nerd Font -> ~/.fonts/JetBrainsMono/, Iosevka and IBM Plex Sans -> ~/.fonts/, then fc-cache -f.
MSG
}
