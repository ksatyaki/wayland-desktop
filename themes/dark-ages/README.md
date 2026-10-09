# Dark Ages desktop theme

A DOOM: The Dark Ages look for the whole desktop, after the game's settings menus: dark teal stone, a thin
Garamond-style serif, rows separated by hairlines, the focused row an orange bar with spear-tipped ends, teal for
everything that is lit. Install with `./install.sh --theme dark-ages` together with the components you want; the
files under `config/` here are laid over the repo's `config/` (same paths), so only the files that differ live here.

| Piece | File | What changes |
|---|---|---|
| Bar | `config/waybar/style.css` + `dark-ages-*.png` | Translucent stone texture (Hyprland blurs the wallpaper behind it), Cormorant, hairline separators, the active workspace on an orange spear-tipped bar, hover on a teal one |
| Launcher | `config/fuzzel/fuzzel.ini` | Stone background, hairline frame, selection in the orange of the focused row |
| Notifications | `config/mako/config` | Same stone and hairline; urgent ones get the orange outline |
| Lock screen (Hyprland) | `config/hypr/hyprlock.conf` + `dark-ages-*.png` | Revelations art behind a dark blur, "STAND AND FIGHT" over a rule with four-pointed stars, the password on the orange bar |
| Lock screen (Sway) | `config/swaylock/config` | Same wallpaper and palette, plain ring |
| Window borders, group tabs | `config/hypr/theme.lua`, `config/sway/theme` | Teal glow on the focused window, hairlines elsewhere, orange for a locked group, square corners |
| Wallpaper | `config/waypaper/config.ini` | `~/Pictures/Wallpapers/revelations.jpg` (installed by every component) |
| Qt palette | `config/qt6ct/colors/Dark-Ages.conf`, `config/qt5ct/colors/Dark-Ages.conf` | The stone palette for Fusion; `--enable-theming` points qt6ct/qt5ct at it |
| Font | `config/fontconfig/conf.d/60-cormorant-lnum.conf` | Lining digits for Cormorant (the game's menus have them; the font defaults to old-style ones) |

The font is [Cormorant](https://github.com/CatharsisFonts/Cormorant) (SIL OFL), shared with the Dark Ages login
theme in `sddm/sddm-dark-ages-theme/Fonts/Cormorant/`; the install script copies it to `~/.fonts/cormorant/`. The bar
uses the SemiBold weight at 21 px: the regular weight is too thin at bar size.

## Palette

Sampled from the game's menus, the same values as `sddm/sddm-dark-ages-theme/Themes/dark_ages.conf`.

| Name | Hex | Used for |
|---|---|---|
| stone | `#0a2022` | menu background, bar, launcher, notifications |
| stone2 | `#061a1c` | tooltips, text fields |
| row | `#0f3033` | lit row fill, group tabs, Qt buttons |
| hairline | `#2a4347` | separators, inactive borders |
| rule | `#365557` | the header rule, frames |
| dim | `#5f7f80` | disabled rows, placeholders, muted modules |
| muted | `#86a5a7` | icons at rest |
| text | `#a4bebf` | row text |
| bright | `#e8f4f3` | focused text, the clock |
| teal | `#7fb3ae` | the lit row's glow, sliders, active border |
| orange | `#ff9a5c` | warnings, text on the orange bar |
| ember | `#d0602a` | the orange bar's outline, locked groups |
| ember fill | `#4a2a20` | the orange bar's fill, the launcher's selection |
| red | `#ff5a36` | critical |

## Shapes

`tools/dark-ages-assets.py` renders the PNGs (needs Python with Pillow):

```sh
# bar background: 1024 px strip the height of the bar, tiles horizontally, 88 % opaque
tools/dark-ages-assets.py stone themes/dark-ages/config/waybar/dark-ages-stone.png 1024 44
# spear-tipped bars for the bar (120x36 logical, 14 px tips) and their centre strips
tools/dark-ages-assets.py bar themes/dark-ages/config/waybar/dark-ages-bar-orange.png 120 36 --tip 14 --mid themes/dark-ages/config/waybar/dark-ages-bar-orange-mid.png
tools/dark-ages-assets.py bar themes/dark-ages/config/waybar/dark-ages-bar-teal.png   120 36 --tip 14 --fill 0f3033cc --border 7fb3aeff --mid themes/dark-ages/config/waybar/dark-ages-bar-teal-mid.png
tools/dark-ages-assets.py bar themes/dark-ages/config/waybar/dark-ages-bar-red.png    120 36 --tip 14 --fill 4a1a12e6 --border ff5a36ff --mid themes/dark-ages/config/waybar/dark-ages-bar-red-mid.png
# lock screen: password bar, keyboard-layout bar, header rule
tools/dark-ages-assets.py bar  themes/dark-ages/config/hypr/dark-ages-input.png  560 64
tools/dark-ages-assets.py bar  themes/dark-ages/config/hypr/dark-ages-layout.png 150 32 --fill 0f3033cc --border 7fb3aeff
tools/dark-ages-assets.py rule themes/dark-ages/config/hypr/dark-ages-rule.png   560 16 --star --color 86a5a7ff
```

In the bar's CSS a spear-tipped bar is a `border-image` on 14 px side borders (the two tips, sliced from the PNG)
plus the `*-mid.png` centre column stretched over the padding box as the background, because GTK's `border-image`
never paints the middle. The stone strip is `background-image` on `window#waybar`, repeated horizontally; under
Hyprland `theme.lua` adds a `blur` layer rule for the `waybar` namespace so the wallpaper shows through it blurred.
hyprlock places the same kind of PNG as an `image` under a transparent `input-field`.

## Switching back

`./install.sh --theme eternal` with the same components restores the Catppuccin Mocha / DOOM Eternal look (the
default); the login screen follows `--theme` unless `--login-theme` says otherwise. Then
`systemctl --user restart waybar.service` (or `swaymsg reload`), `makoctl reload`, `waypaper --restore`.
