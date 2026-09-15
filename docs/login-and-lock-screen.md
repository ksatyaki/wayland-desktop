# Login and lock screen

<p align="center">
  <img src="screenshots/login-screen.jpg" alt="DOOM login screen" width="640">
  <img src="screenshots/lock-screen.jpg" alt="DOOM lock screen" width="640">
</p>

## Login screen (SDDM)

- Theme: [sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme) (Qt6 QML) with a custom `doom` preset. Master copy in `~/.config/sddm-doom-theme/`, installed copy in `/usr/share/sddm/themes/sddm-astronaut-theme/`.
- Install or reinstall: `./install.sh --enable-login` from the repo, or `sudo sh ~/.config/sddm-doom-theme/install-sddm-theme.sh` from the master copy (copies the theme, installs its fonts, writes `/etc/sddm.conf.d/10-theme.conf` and `20-users.conf`).
- Needs SDDM >= 0.21 built with Qt 6 and the Qt modules the theme imports: QtQuick.Controls, Layouts, Shapes, Effects, QtMultimedia and QtQuick.VirtualKeyboard (package names per distro in the README). On Fedora the greeter runs on KWin (`sddm-wayland-plasma`).
- Username is prefilled with the last login and the cursor starts in the password field (`ForceLastUser`, `PasswordFocus` in the preset, `RememberLastUser` in SDDM).
- Fonts: fan-made DOOM Eternal UI fonts (`Eternal UI`, `Eternal UI 2`) in `~/.fonts/doom/` for the session and in the theme's `Fonts/` dir (the install script puts them in `/usr/share/fonts/` for the greeter).
- Eternal-style shapes: fields, login button, dropdowns and power buttons are drawn by `Components/EternalShape.qml` (a QtQuick.Shapes polygon with per-corner chamfers: the fields are elongated hexagons, the login button and dropdown highlight are parallelograms, the popups are cards with four small cuts). The preset's colours follow the Eternal menu: olive panels (`LoginFieldBackgroundColor`), light-green outline (`FieldBorderColor`, a key added to the theme; `HighlightBorderColor` when focused) and orange for the active login button (`LoginButtonBackgroundColor`). Other presets ignore the new key and fall back to no outline.
- Change the look: edit `Themes/doom.conf` in the installed copy (`Background=` takes png/jpg/gif/mp4/webm relative to the theme dir, `HeaderText`, colours, `Font`). Preview without logging out:

  ```sh
  sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-astronaut-theme
  ```

- The other presets that ship with the upstream theme (`Themes/*.conf`) still work: point `ConfigFile=` in `metadata.desktop` at one of them.

## Lock screen

- Hyprland: `~/.config/hypr/hyprlock.conf`, started by hypridle (after 10 minutes idle and before sleep) or with the lock keybinding. It uses the same wallpaper (`~/Pictures/Wallpapers/DOOM95.jpeg`), fonts and colours as the login theme.
- hyprlock can only draw rectangles, so its chamfered panels are PNGs in `~/.config/hypr/` (`eternal-input.png` behind the password field, `eternal-layout.png` behind the keyboard-layout label) rendered by `tools/eternal-panel.py` in the repo (needs Python with Pillow). The `input-field` is transparent on top of the image and only draws the dots, the placeholder and the red failure outline. Regenerate the panels after changing colours or sizes:

  ```sh
  python3 tools/eternal-panel.py ~/.config/hypr/eternal-input.png 480 70    # OUT.png WIDTH HEIGHT, see --help for --fill, --border, --cut
  python3 tools/eternal-panel.py ~/.config/hypr/eternal-layout.png 200 40
  ```

  Sizes are logical pixels (the PNG is rendered at 2x); hyprlock's `size` for the image is the HEIGHT.

- Sway: `~/.config/swaylock/config` (`$lock` in the Sway config is plain `swaylock -f`). swaylock has no image widgets, so the Sway lock screen keeps its plain ring indicator in the same colours.
- To take a screenshot of the lock screen from a terminal under Hyprland: start `hyprlock`, run `grim` from another process a few seconds later, then `pkill -USR1 hyprlock` unlocks it.
