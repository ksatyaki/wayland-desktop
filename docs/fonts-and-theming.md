# Fonts and theming

## Fonts

The fonts are plain `.ttf` files in the user font directories; fontconfig picks them up with no
install step (`fc-cache -f` after adding new ones, then restart the app that should use them).

| Location | Contents |
|---|---|
| `~/.fonts/doom/` | The DOOM Eternal UI fonts from this repo (`Eternal UI`, `Eternal UI 2`), installed by `./install.sh` |
| `~/.fonts/JetBrainsMono/` | JetBrainsMono Nerd Font, all weights. Not in the repo; this is the font every icon refers to |
| `~/.fonts/` | Other user fonts (Iosevka, IBM Plex Sans, ...). Not in the repo |
| `/usr/share/fonts/` | System fonts installed by the package manager (Noto, Cantarell, DejaVu, ...) and the login theme's fonts (`sddm-astronaut-theme/`) |

Useful: `fc-list : family | sort -u` lists usable family names, `fc-match "Name"` shows which file a
name resolves to. The family name to use in configs is `JetBrainsMono Nerd Font`; the icons come from
its private-use glyphs, so anything that shows bar icons must keep a Nerd Font in its font stack.

Where each font is set (change the name or size here):

| What | File and line | Setting |
|---|---|---|
| Bar (Waybar) | `~/.config/waybar/style.css`, the `*` block near the top | Text: `font-family: "Eternal UI", ...; font-size: 19px;` (workspace numbers and clock use the caps-only `Eternal UI 2` bold in their own blocks). Bar `height` is 44 in both `config*.jsonc`; Waybar warns if it is below what the modules need. Icons: each icon in the two `config*.jsonc` is a `<span size='large' font_family='JetBrainsMono Nerd Font'>`, so they keep the Nerd Font whatever the text font is |
| Super+D launcher (fuzzel) | `~/.config/fuzzel/fuzzel.ini`, `[main]` | `font=Eternal UI:size=14` |
| Sway titles / swaynag | `~/.config/sway/config` | `font pango:Eternal UI Bold 11` (caps-only weight) |
| Hyprland (group bars, dialogs) | `~/.config/hypr/hyprland.lua`, `groupbar` and `misc` blocks | `font_family = "Eternal UI"`, group bar in the bold (caps-only) weight |
| Lock screen (hyprlock) | `~/.config/hypr/hyprlock.conf` | `$font` (fields) and `$hfont` (header, clock) at the top, `font_size` per label |
| Lock screen (swaylock) | `~/.config/swaylock/config` | `font=Eternal UI`, `font-size=26` |
| Notifications (mako) | `~/.config/mako/config` | `font=Eternal UI 12` |
| Login screen (SDDM) | `Themes/doom.conf` in the theme | `Font` (fields, buttons) and `HeaderFont` (header text and clock, bold) |
| Terminal (Tabby) | Tabby settings, Appearance | GUI setting, not a file managed here |

The DOOM fonts: `Eternal UI` and `Eternal UI 2` regular weights are condensed sans faces with real lowercase; both bold weights are caps-only (lowercase renders as capitals, `Eternal UI 2` bold has the slashed O), so they are used only for title bars, workspace numbers, the clock and headers. GTK and Qt apps stay on IBM Plex Sans.

After editing: `swaymsg reload` (Sway + bar), Hyprland reloads on save (bar needs a restart, see the handy commands in [setup-notes.md](setup-notes.md)),
`makoctl reload` for mako; fuzzel reads its file on every launch.

## App theming (Qt and GTK)

Without a Plasma session there is no Qt platform theme (`plasma-integration`), so Qt apps such as
pcmanfm-qt and qpdfview have no icon theme, style or font. The replacement is qt6ct (Qt6) and qt5ct (Qt5):

- Packages: `qt6ct qt5ct breeze-icon-theme` (optional: `kvantum` for SVG-based Qt styles, `papirus-icon-theme`). `./install.sh --enable-theming --packages` installs them.
- `QT_QPA_PLATFORMTHEME=qt6ct` is exported in `~/.zprofile` and set in `hyprland.lua`; Qt5 apps automatically use qt5ct with the same value.
- Run `qt6ct` (and `qt5ct`) to pick style, icon theme, palette and fonts with a GUI; changes apply to newly started apps.
  The Catppuccin palette is in `~/.config/qt6ct/colors/`.
- Style: **Fusion** (built into Qt). It takes every colour from the qt6ct palette. Do not use the Breeze style
  (`plasma-breeze`) outside Plasma: it paints menu bars, toolbars and frames from KDE's own colour scheme
  (`~/.config/kdeglobals`, falling back to Breeze Light when the file is missing), so with a dark palette the
  menu text comes out near-black on dark. Kvantum is the other style that honours the palette.
- Icon themes: `breeze`, `breeze-dark` (system) plus whatever is in `~/.local/share/icons/` (Tela, WhiteSur, McMojave-circle, candy-icons, ...).
  The same names work in GTK's `gtk-icon-theme-name` and qt6ct's `icon_theme`, so both toolkits can share one icon set.
- GTK apps read `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini` (Adwaita theme, breeze icons, IBM Plex Sans 13).
  `nwg-look` is a GUI for these files. Themes go in `~/.themes/` or `/usr/share/themes/`.
- Qt apps read qt6ct settings only at startup, and pcmanfm-qt is single-instance: after changing anything, `pkill pcmanfm-qt` (or quit the app fully) and relaunch.
- Leftovers from a previous Plasma install override all of the above: `~/.config/kdeglobals` and `kdedefaults/`
  (read by Breeze and any KDE library), `Trolltech.conf`, `xsettingsd/` and `gtkrc*` (written by Plasma's krdb),
  and the `gtk-modules=colorreload-gtk-module:...` line kde-gtk-config adds to the GTK settings.
  `tools/purge-kde-config.sh` (`--dry-run` to preview) archives them to `~/.local/state/` and removes them,
  together with the rest of the Plasma session state; settings of KDE apps that are still installed are kept.
- Default apps for file types (e.g. folders opening in the wrong program) are in `~/.config/mimeapps.list`; fix with `xdg-mime default pcmanfm-qt.desktop inode/directory`.
- Cursor: `XCURSOR_SIZE` / `HYPRCURSOR_SIZE` in `hyprland.lua`, `seat * xcursor_theme` in the Sway config, `gtk-cursor-theme-name` for GTK apps. Themes in `~/.icons/`.
- The qt6ct, qt5ct and waypaper configs contain an absolute path into the home directory; `./install.sh` rewrites it to `$HOME` when copying.
