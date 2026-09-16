# sddm-dark-ages-theme

A [DOOM: The Dark Ages](https://bethesda.net/en/game/doom-the-dark-ages) style login screen for the [SDDM](https://github.com/sddm/sddm/) display manager.
It is a restyle of **[sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme)** by **[Keyitdev](https://github.com/Keyitdev)** (Qt6 QML, virtual keyboard, animated wallpapers, one config file per look) and keeps its structure, its presets and its licence; only the look is new:

- `Themes/dark_ages.conf`: the palette of the Dark Ages menus (dark teal stone, pale text, a teal glow on the focused row, orange for the confirm button), header text "STAND AND FIGHT", the Cormorant serif.
- `Components/DarkAgesBar.qml`, `DarkAgesRule.qml`, `DarkAgesStar.qml`: the menu rows. At rest a row is text over a hairline that fades at both ends; the focused row is a bar with spear-tip ends (teal for the fields, orange for the login button), the header has a rule with a four-pointed star.
- `Backgrounds/dark_ages.jpg`: a generated dark teal stone texture (`tools/dark-ages-background.py` in the repo), so no game art is shipped.
- `Fonts/Cormorant/`: [Cormorant](https://github.com/CatharsisFonts/Cormorant) by Christian Thalmann (SIL Open Font License, see `Fonts/Cormorant/OFL.txt`), a Garamond-style serif close to the Dark Ages menu font. `Main.qml` loads it from the theme directory, so it works without a system-wide font install.

Keys added to the preset format: `FieldBorderColor` (hairline), `LoginButtonBorderColor` (outline of the orange bar) and `HeaderRuleColor`. The upstream presets in `Themes/` still load and ignore them.

## Installation

From the wayland-desktop repo: `./install.sh --enable-login --login-theme dark-ages`, or `sudo sh sddm/install-sddm-theme.sh dark-ages`. Manually: copy this directory to `/usr/share/sddm/themes/sddm-dark-ages-theme`, set `Current=sddm-dark-ages-theme` under `[Theme]` in `/etc/sddm.conf.d/10-theme.conf`, and install the dependencies below.

Dependencies: [`sddm >= 0.21.0`](https://github.com/sddm/sddm), [`qt6 >= 6.8`](https://doc.qt.io/qt-6/index.html) with `qt6-svg`, `qt6-virtualkeyboard` and `qt6-multimedia` (QtQuick.Controls, Layouts, Shapes, Effects).

```sh
sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg     # Arch
sddm qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia      # Fedora
sddm qt6-svg-dev qml6-module-qtquick-virtualkeyboard qt6-multimedia-dev qml6-module-qtquick-controls qml6-module-qtquick-effects libxcb-cursor0 # Debian trixie (13.5)
```

## Previewing

```sh
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-dark-ages-theme/
```

## Selecting another preset

`ConfigFile=` in `metadata.desktop` picks the preset; the upstream presets in `Themes/` still work (they will get the Dark Ages rows, since the shapes live in the components).

## Acknowledgements

Everything below is from the upstream sddm-astronaut-theme README and applies to this theme as well.

## Sources

Initially the theme was independed fork of [MarianArlt's theme](https://github.com/MarianArlt/sddm-sugar-dark) but now the project has come a long way and started to significantly deviate from the original.
Many of the wallpapers and fonts used in this project are very popular and copied from one user to another, so I don't know who the original creator is. 
I also redesigned many of them, but here are links to some of the orginal artists who created these wonderful wallpapers:

- Astronaut: [wallpaper](https://wallhaven.cc/w/e76pew), [font](https://fonts.google.com/specimen/Open+Sans/about)
- Black hole: [wallpaper](https://images2.alphacoders.com/114/1141632.jpg), [font](https://www.1001fonts.com/espacion-font.html)
- Japanese aesthetic: [wallpaper](https://imgur.com/a/pua0dYx) by [gharly](https://www.artstation.com/gharly), [font](https://www.1001fonts.com/electroharmonix-font.html)
- Purple leaves: [wallpaper](https://wallha.com/wallpaper/artwork-abstract-leaves-purple-texture-pattern-1414432), [font](https://fonts.google.com/specimen/Open+Sans/about)
- Cyberpunk: [wallpaper](https://images5.alphacoders.com/133/1330479.png) by [patrika](https://alphacoders.com/users/profile/227699/patrika), [font](https://www.1001fonts.com/kognigear-font.html)
- Post-apocalyptic hacker:  [wallpaper](https://images.alphacoders.com/137/thumb-1920-1375178.png) by [patrika](https://alphacoders.com/users/profile/227699/patrika), [font](https://www.1001fonts.com/fragile-bombers-font.html)
- Hyprland Kath: [wallpaper](https://motionbgs.com/andvari-last-origin), [font](https://www.1001fonts.com/pixelon-font.html)
- Pixel sakura: [wallpaper](https://imgur.com/gallery/sakura-tree-with-petals-flying-off-t5tg4N8), [font](https://www.1001fonts.com/arcadeclassic-font.html)
- Jake the dog: [wallpaper](https://motionbgs.com/jake-the-dog), [font](https://fontmeme.com/fonts/thunderman-font/)
  
## Supporting project

You can support me simply by dropping a **star** on **[github](https://github.com/Keyitdev/sddm-astronaut-theme)** or giving a **subscription** on **[YouTube](http://www.youtube.com/channel/UCVoGVyAP2sHPQyegwBMJKyQ?sub_confirmation=1)**.

If you enjoyed it and would like to show your appreciation, you can make a **[donation](https://ko-fi.com/keyitdev)** using **[kofi](https://ko-fi.com/keyitdev)**.

[![Ko-fi](https://img.shields.io/badge/support_me_on_ko--fi-F16061?style=for-the-badge&logo=kofi&logoColor=f5f5f5)](https://ko-fi.com/keyitdev)

Distributed under the **[GPLv3+](https://www.gnu.org/licenses/gpl-3.0.html) License**.    
Copyright (C) 2022-2025 Keyitdev.
