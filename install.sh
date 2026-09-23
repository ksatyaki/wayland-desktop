#!/bin/sh
# Installs the parts of this desktop you pick. Run ./install.sh --help for the options.
set -e
REPO=$(cd "$(dirname "$0")" && pwd)
STAMP=$(date +%Y%m%d-%H%M%S)

usage() {
    cat <<'EOF'
Usage: ./install.sh [components...] [--packages]

Components (combine freely):
  --enable-hyprland   Hyprland config with the hyprlock lock screen and hypridle   -> ~/.config/hypr
  --enable-sway       Sway config with kanshi and swaylock, "Sway (NVIDIA)" session file (sudo)
  --enable-bar        Waybar, fuzzel launcher, mako notifications, waypaper wallpaper (shared by both compositors)
  --enable-theming    Qt/GTK app look: qt6ct, qt5ct, GTK settings, default apps, ~/.zprofile
  --enable-login      DOOM login screen for SDDM (system-wide, sudo); see --login-theme
  --enable-fonts      DOOM Eternal UI fonts -> ~/.fonts/doom (the other components pull this in themselves)
  --all               Everything above

Options:
  --login-theme NAME  Which login screen --enable-login installs: eternal (DOOM Eternal look, default)
                      or dark-ages (DOOM: The Dark Ages look)
  --packages          Also install the distro packages the selected components need
                      (dnf on Fedora, apt on Ubuntu/Debian; asks for sudo)
  -h, --help          This text

Existing config is kept as <file>.bak-<timestamp>. Only --enable-login, the Sway session file and
--packages use sudo.
EOF
}

HYPR=0; SWAY=0; BAR=0; THEMING=0; LOGIN=0; FONTS=0; PACKAGES=0; LOGIN_THEME=eternal
[ $# -eq 0 ] && { usage; exit 2; }
expect_theme=0
for a in "$@"; do
    if [ $expect_theme = 1 ]; then LOGIN_THEME=$a; expect_theme=0; continue; fi
    case "$a" in
        --enable-hyprland) HYPR=1;;
        --enable-sway)     SWAY=1;;
        --enable-bar)      BAR=1;;
        --enable-theming)  THEMING=1;;
        --enable-login)    LOGIN=1;;
        --enable-fonts)    FONTS=1;;
        --all)             HYPR=1; SWAY=1; BAR=1; THEMING=1; LOGIN=1; FONTS=1;;
        --packages)        PACKAGES=1;;
        --login-theme)     expect_theme=1;;
        --login-theme=*)   LOGIN_THEME=${a#--login-theme=};;
        -h|--help)         usage; exit 0;;
        *) echo "unknown option: $a" >&2; usage >&2; exit 2;;
    esac
done
if [ $((HYPR + SWAY + BAR + THEMING + LOGIN + FONTS)) -eq 0 ]; then
    echo "nothing selected: pass at least one --enable-* flag or --all" >&2; exit 2
fi
case "$LOGIN_THEME" in
    eternal)   LOGIN_DIR=sddm-astronaut-theme;;
    dark-ages) LOGIN_DIR=sddm-dark-ages-theme;;
    *) echo "unknown --login-theme: $LOGIN_THEME (eternal or dark-ages)" >&2; exit 2;;
esac

# ---------------------------------------------------------------- distro packages
. /etc/os-release 2>/dev/null || true
case " $ID $ID_LIKE " in
    *fedora*|*rhel*)   PM=dnf;;
    *debian*|*ubuntu*) PM=apt;;
    *)                 PM="";;
esac

PKGS_BAR_dnf="waybar fuzzel mako brightnessctl ddcutil playerctl grim slurp wl-clipboard wdisplays waypaper awww \
pavucontrol nm-connection-editor blueman gnome-keyring xdg-desktop-portal-gtk"
PKGS_BAR_apt="waybar fuzzel mako-notifier brightnessctl ddcutil playerctl grim slurp wl-clipboard wdisplays \
pavucontrol network-manager-gnome blueman gnome-keyring xdg-desktop-portal-gtk pipx"
PKGS_THEMING_dnf="pcmanfm-qt qt6ct qt5ct kvantum breeze-icon-theme"
PKGS_THEMING_apt="pcmanfm-qt qt6ct qt5ct qt6-style-kvantum breeze-icon-theme"
PKGS_LOGIN_dnf="sddm qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia"
PKGS_LOGIN_apt="sddm libqt6svg6 qml6-module-qtquick-controls qml6-module-qtquick-layouts qml6-module-qtquick-shapes \
qml6-module-qtquick-effects qml6-module-qtmultimedia qml6-module-qtquick-virtualkeyboard libxcb-cursor0"
PKGS_SWAY_dnf="sway swaylock swayidle swaybg kanshi xdg-desktop-portal-wlr"
PKGS_SWAY_apt="sway swaylock swayidle swaybg kanshi xdg-desktop-portal-wlr"
PKGS_HYPR_dnf="hyprland hyprlock hypridle hyprpolkitagent hyprshot hyprshutdown hyprland-guiutils xdg-desktop-portal-hyprland"
PKGS_HYPR_apt=""   # Ubuntu/Debian ship Hyprland < 0.56, which cannot read the Lua config: build from source (see below)

install_packages() {
    if [ -z "$PM" ]; then
        echo "Unknown distro ($ID): install the packages listed in README.md yourself, then re-run without --packages." >&2
        exit 1
    fi
    pkgs=""
    [ $BAR = 1 ]     && pkgs="$pkgs $(eval echo \$PKGS_BAR_$PM)"
    [ $THEMING = 1 ] && pkgs="$pkgs $(eval echo \$PKGS_THEMING_$PM)"
    [ $LOGIN = 1 ]   && pkgs="$pkgs $(eval echo \$PKGS_LOGIN_$PM)"
    [ $SWAY = 1 ]    && pkgs="$pkgs $(eval echo \$PKGS_SWAY_$PM)"
    [ $HYPR = 1 ]    && pkgs="$pkgs $(eval echo \$PKGS_HYPR_$PM)"
    echo "Packages ($PM, sudo):$pkgs"
    if [ "$PM" = dnf ]; then
        [ $HYPR = 1 ] && sudo dnf copr enable -y lionheartp/Hyprland   # Hyprland left Fedora proper
        sudo dnf install -y $pkgs
    else
        sudo apt update
        sudo apt install -y $pkgs
        [ $BAR = 1 ] && cat <<'MSG'

Ubuntu/Debian notes for --enable-bar:
  waypaper is not packaged:  pipx install waypaper
  awww (wallpaper daemon) is not packaged: get a release from https://github.com/LGFae/awww or cargo install it.
MSG
        [ $HYPR = 1 ] && cat <<'MSG'

Ubuntu/Debian notes for --enable-hyprland:
  The config uses the Lua format of Hyprland >= 0.56, newer than the apt packages. Build Hyprland, hyprlock,
  hypridle, hyprpolkitagent, hyprshot and xdg-desktop-portal-hyprland from source: https://wiki.hyprland.org/Getting-Started/Installation/
MSG
        [ $SWAY = 1 ] && cat <<'MSG'

Ubuntu/Debian notes for --enable-sway:
  The Sway config starts hyprpolkitagent; without it install another agent (e.g. polkit-kde-agent-1 or lxpolkit)
  and change the exec line under "polkit agent" in ~/.config/sway/config.
MSG
        [ $LOGIN = 1 ] && cat <<'MSG'

Ubuntu/Debian notes for --enable-login:
  The theme needs SDDM >= 0.21 built with Qt 6 (ls /usr/bin/sddm-greeter-qt6 to check). Ubuntu 24.04 ships an older Qt 5 SDDM.
MSG
    fi
}

# ---------------------------------------------------------------- helpers
# put <repo>/config/<name> at ~/.config/<name>, keeping a timestamped backup of whatever was there
put_config() {
    src="$REPO/config/$1"; dst="$HOME/.config/$1"
    if [ -e "$dst" ]; then
        if diff -rq "$src" "$dst" >/dev/null 2>&1; then echo "  $dst (unchanged)"; return 0; fi
        mv "$dst" "$dst.bak-$STAMP"; echo "  backup: $dst.bak-$STAMP"
    fi
    mkdir -p "$(dirname "$dst")"; cp -r "$src" "$dst"; echo "  $dst"
    # a few tools write absolute paths into their config; point them at this user's home
    find "$dst" -type f \( -name '*.conf' -o -name '*.ini' \) -exec sed -i "s#/home/ksatyaki#$HOME#g" {} +
}

FONTS_DONE=0
install_fonts() {
    [ $FONTS_DONE = 1 ] && return 0; FONTS_DONE=1
    echo "Fonts:"
    mkdir -p "$HOME/.fonts/doom"
    cp "$REPO"/fonts/doom/*.ttf "$HOME/.fonts/doom/"; fc-cache -f >/dev/null; echo "  ~/.fonts/doom (Eternal UI, Eternal UI 2)"
}

WALL_DONE=0
install_wallpaper() {
    [ $WALL_DONE = 1 ] && return 0; WALL_DONE=1
    mkdir -p "$HOME/Pictures/Wallpapers"
    cp "$REPO"/wallpapers/* "$HOME/Pictures/Wallpapers/"; echo "  ~/Pictures/Wallpapers (DOOM95.jpeg, used by the lock screens and waypaper)"
}

# ---------------------------------------------------------------- DDC/CI (external monitor brightness)
# The bar controls each monitor's own brightness: the laptop panel through /sys/class/backlight,
# external monitors over DDC/CI, which needs read/write on the /dev/i2c-* buses. ddcutil ships the
# udev rule for that; it only applies to device nodes created after the package landed, so re-trigger it.
enable_ddc() {
    command -v ddcutil >/dev/null 2>&1 || { echo "  external monitor brightness: install ddcutil to enable it"; return 0; }
    sudo modprobe i2c-dev 2>/dev/null || true
    [ -e /etc/modules-load.d/i2c-dev.conf ] || echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
    sudo udevadm control --reload-rules
    sudo udevadm trigger --subsystem-match=i2c-dev --subsystem-match=dri
    if ! ddcutil detect 2>&1 | grep -q "not readable and writable"; then
        echo "  external monitor brightness: DDC/CI ready ($(ddcutil detect --terse 2>/dev/null | grep -c '^Display') monitor(s) answer)"
        return 0
    fi
    # Fedora's rule tags the buses uaccess, so the active session gets an ACL and no group is involved;
    # distros whose rule sets GROUP="i2c" need the user in that group, which lands on the next login.
    if grep -qs 'GROUP="i2c"' /usr/lib/udev/rules.d/*ddcutil*.rules /etc/udev/rules.d/*ddcutil*.rules; then
        getent group i2c >/dev/null || sudo groupadd --system i2c
        id -nG | tr ' ' '\n' | grep -qx i2c || sudo usermod -aG i2c "$USER"
        echo "  external monitor brightness: added $USER to the i2c group -- log out and back in"
    else
        echo "  external monitor brightness: /dev/i2c-* still unreadable -- log out and back in, then check with: ddcutil detect"
    fi
}

# ---------------------------------------------------------------- components
[ $PACKAGES = 1 ] && install_packages

if [ $FONTS = 1 ]; then install_fonts; fi

if [ $BAR = 1 ]; then
    install_fonts
    echo "Bar, launcher, notifications, wallpaper:"
    for d in waybar mako fuzzel waypaper; do put_config "$d"; done
    chmod +x "$HOME/.config/waybar/scripts/perf.sh" "$HOME/.config/waybar/scripts/gpu.sh" \
             "$HOME/.config/waybar/scripts/brightness.sh"
    enable_ddc
    install_wallpaper
fi

if [ $THEMING = 1 ]; then
    echo "App theming (Qt/GTK):"
    for d in qt6ct qt5ct gtk-3.0 gtk-4.0 fontconfig alacritty mimeapps.list; do put_config "$d"; done
    if [ -e "$HOME/.zprofile" ] && ! cmp -s "$REPO/home/.zprofile" "$HOME/.zprofile"; then
        cp "$HOME/.zprofile" "$HOME/.zprofile.bak-$STAMP"; echo "  backup: ~/.zprofile.bak-$STAMP"
    fi
    cp "$REPO/home/.zprofile" "$HOME/.zprofile"; echo "  ~/.zprofile (exports QT_QPA_PLATFORMTHEME=qt6ct, FREETYPE_PROPERTIES)"
    xdg-mime default pcmanfm-qt.desktop inode/directory 2>/dev/null || true
fi

if [ $HYPR = 1 ]; then
    install_fonts
    echo "Hyprland:"
    put_config hypr
    install_wallpaper
fi

if [ $SWAY = 1 ]; then
    install_fonts
    echo "Sway:"
    for d in sway kanshi swaylock; do put_config "$d"; done
    install_wallpaper
    echo "  session file (sudo): /usr/local/share/wayland-sessions/sway-nvidia.desktop"
    sudo mkdir -p /usr/local/share/wayland-sessions
    sudo cp "$REPO/system/wayland-sessions/sway-nvidia.desktop" /usr/local/share/wayland-sessions/
    sudo usermod -aG video "$USER"
fi

if [ $LOGIN = 1 ]; then
    echo "Login screen:"
    mkdir -p "$HOME/.config/sddm-doom-theme"; cp -r "$REPO/sddm/." "$HOME/.config/sddm-doom-theme/"
    echo "  ~/.config/sddm-doom-theme (editable master copy)"
    echo "  /usr/share/sddm/themes/$LOGIN_DIR and /etc/sddm.conf.d (sudo)"
    sudo sh "$REPO/sddm/install-sddm-theme.sh" "$LOGIN_THEME"
fi

# ---------------------------------------------------------------- what is left to do by hand
echo
echo "Done."
if [ $((BAR + HYPR + SWAY + THEMING)) -gt 0 ]; then
    echo "Fonts not in this repo (see README): JetBrainsMono Nerd Font -> ~/.fonts/JetBrainsMono/, Iosevka and IBM Plex Sans -> ~/.fonts/, then fc-cache -f."
fi
if [ $((HYPR + SWAY)) -gt 0 ]; then
    echo "Monitor layouts are the author's: edit the monitor lines near the top of ~/.config/hypr/hyprland.lua, ~/.config/sway/config and ~/.config/kanshi/config."
fi
[ $HYPR = 1 ]  && echo "Log out and pick \"Hyprland\" in the login screen."
[ $SWAY = 1 ]  && echo "Log out and pick \"Sway (NVIDIA)\" (or plain \"Sway\" without an NVIDIA GPU) in the login screen."
[ $LOGIN = 1 ] && echo "The DOOM login screen appears at the next logout. Preview now: sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/$LOGIN_DIR"
exit 0
