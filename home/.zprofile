# Sourced by the login shell SDDM uses to start the Wayland session (Sway and Hyprland inherit this).
export QT_QPA_PLATFORMTHEME=qt6ct     # Qt apps read style/icons/fonts from ~/.config/qt6ct (qt5ct for Qt5 apps)

# FreeType v35 TrueType interpreter + CFF stem darkening (the pre-2016 / Fedora 8 look).
# Set here for Sway and any login-shell session; Hyprland sets it again in hyprland.lua.
export FREETYPE_PROPERTIES="truetype:interpreter-version=35 cff:no-stem-darkening=0"
