# wayland-desktop

Sway + Hyprland desktop for a Fedora 44 laptop (NVIDIA RTX 4060, discrete only). Everything needed to rebuild it lives here: configs mirroring `~/.config`, the DOOM login and lock screens, fonts, wallpaper, and two install scripts. `refcard.html` is the one-page cheatsheet (open it in a browser).

## Restore on a fresh machine

```sh
git clone git@github.com:ksatyaki/wayland-desktop.git && cd wayland-desktop
./install_hyprland_config.sh --packages --system   # Hyprland
./install_sway_config.sh     --packages --system   # Sway (both can be run; shared parts are identical)
```

Without flags the scripts only copy user config (existing files are backed up as `*.bak-<timestamp>`). `--packages` runs dnf, `--system` installs the SDDM theme, Sway session file and video group with sudo. Fonts not in the repo (JetBrainsMono Nerd Font, Iosevka, IBM Plex Sans) go in `~/.fonts/`.

## Layout

| Path | Installed to |
|---|---|
| `config/*` | `~/.config/*` |
| `home/.zprofile` | `~/.zprofile` |
| `fonts/doom/` | `~/.fonts/doom/` |
| `wallpapers/` | `~/Pictures/Wallpapers/` |
| `sddm/` | `~/.config/sddm-doom-theme/` and, via `sddm/install-sddm-theme.sh`, `/usr/share/sddm/themes/`, `/etc/sddm.conf.d/` |
| `system/wayland-sessions/sway-nvidia.desktop` | `/usr/local/share/wayland-sessions/` |
| `tools/` | not installed: `eternal-panel.py` regenerates the chamfered PNG panels used by hyprlock |

Binary files (fonts, wallpaper) are tracked with Git LFS.

# Setup notes

Set up on 2026-09-11, ported from the old `~/.i3/config`. Both compositors share the same
keybindings (i3-style: Super as mod, j/k/l/; for focus), the same Waybar bar, and the same
Catppuccin Mocha palette.

## Config files

### Sway

| File | Purpose |
|---|---|
| `~/.config/sway/config` | Window manager: keybindings ported from i3, gaps, monitor layout by make/model/serial, media keys, floating rule for pavucontrol, autostart (waybar, mako, swayidle, polkit agent, Tabby, Claude, VS Code Insiders) |
| `/usr/local/share/wayland-sessions/sway-nvidia.desktop` | SDDM session entry that launches Sway with `--unsupported-gpu` (required on the proprietary NVIDIA driver) |

### Bar and notifications (shared)

| File | Purpose |
|---|---|
| `~/.config/waybar/config.jsonc` | Bar modules for Sway, bottom position, hover volume slider, icons written as `\u` escapes |
| `~/.config/waybar/config-hyprland.jsonc` | Same bar using the `hyprland/*` workspace, window, submap and language modules |
| `~/.config/waybar/style.css` | Solid Catppuccin Mocha stylesheet, 15px JetBrainsMono Nerd Font, workspace highlight for both compositors, slider styling |
| `~/.config/mako/config` | Notification daemon in the same palette |
| `~/.config/kanshi/config` | Monitor profiles (laptop / home / office) for Sway, incl. disabling eDP-1 at the office |
| `~/.config/fuzzel/fuzzel.ini` | Super+D launcher: font, colours, size |
| `~/.config/qt6ct/qt6ct.conf`, `~/.config/qt5ct/qt5ct.conf` | Qt app look: Breeze style, breeze-dark icons, Catppuccin palette (`colors/Catppuccin-Mocha.conf`), fonts. Edit with the `qt6ct` / `qt5ct` GUI |
| `~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini` | GTK app look: theme, icon theme, font, cursor (left over from Plasma, still valid) |
| `~/.config/kdeglobals` | Deleted on purpose: the Breeze Qt style paints menu bars and toolbars from it if it exists, overriding the qt6ct palette. Plasma-era original kept as `kdeglobals.bak-plasma`; a matching Catppuccin scheme is in `~/.local/share/color-schemes/` if it is ever needed again |
| `~/.zprofile` | Exports `QT_QPA_PLATFORMTHEME=qt6ct` for the whole session (SDDM starts the session via a zsh login shell); Hyprland also sets it in `hyprland.lua` |

### Hyprland

| File | Purpose |
|---|---|
| `~/.config/hypr/hyprland.lua` | Compositor config in the Hyprland >= 0.56 Lua format: same keybindings, monitor layout, NVIDIA and Electron environment, window rules, autostart |
| `~/.config/waypaper/config.ini` | Wallpaper: folder, backend (awww) and last picked image; written by waypaper. `hyprpaper.conf` is kept but unused |
| `~/.config/hypr/hypridle.conf` | Lock after 10 minutes, screen off after 15, lock before sleep |
| `~/.config/hypr/hyprlock.conf` | Lock screen |

### System and keyring

| File | Purpose |
|---|---|
| `/etc/sddm.conf.d/10-theme.conf` | SDDM login theme set to `sddm-astronaut-theme` (see Login screen below) |
| `~/.config/sddm-doom-theme/` | Master copy of the login theme, DOOM preset and its install script |
| `~/.local/share/keyrings/default` | Marks the `login` keyring as the default for Secret Service apps (Claude, browsers) |

## Not files, but needed to reproduce

- Hyprland packages come from the `lionheartp/Hyprland` COPR (Hyprland was retired from Fedora proper):
  `sudo dnf copr enable lionheartp/Hyprland`
- Installed: `sway waybar swaylock swayidle swaybg fuzzel mako brightnessctl playerctl network-manager-applet blueman grim slurp xdg-desktop-portal-wlr`
  and `hyprland hyprlock hypridle hyprpolkitagent hyprshot hyprshutdown hyprland-guiutils xdg-desktop-portal-hyprland`, plus `wdisplays`, `sddm-themes`, and `waypaper awww` for wallpapers.
- Plasma was removed but `kwin`, `sddm-wayland-plasma`, `kde-settings-sddm` and `plasma-keyboard` are kept so SDDM's
  greeter keeps running on KWin. They are marked `dnf mark user` so `dnf autoremove` leaves them alone.
- gnome-keyring is unlocked at login by the PAM stack in `/etc/pam.d/sddm` (already present on Fedora).

## Fonts

The fonts are plain `.ttf` files in the user font directories; fontconfig picks them up with no
install step (`fc-cache -f` after adding new ones, then restart the app that should use them).

| Location | Contents |
|---|---|
| `~/.fonts/JetBrainsMono/` | JetBrainsMono Nerd Font, all weights. This is the font every config below refers to |
| `~/.fonts/` | Other user fonts (Cascadia, Fira, Iosevka, Monaspace, IBM Plex, Red Hat, Victor, Terminus, ...) |
| `~/.local/share/fonts/` | A few more user fonts (Monaspace variable, `NFM.ttf`) |
| `/usr/share/fonts/` | System fonts installed by dnf (Noto, Cantarell, DejaVu, ...) |

Useful: `fc-list : family | sort -u` lists usable family names, `fc-match "Name"` shows which file a
name resolves to. The family name to use in configs is `JetBrainsMono Nerd Font`; the icons come from
its private-use glyphs, so anything that shows bar icons must keep a Nerd Font in its font stack.

Where each font is set (change the name or size here):

| What | File and line | Setting |
|---|---|---|
| Bar (Waybar) | `~/.config/waybar/style.css`, the `*` block near the top | Text: `font-family: "Eternal UI", ...; font-size: 19px;` (workspace numbers and clock use the caps-only `Eternal UI 2` bold in their own blocks) (bar `height` is 44 in both `config*.jsonc`; Waybar warns if it is below what the modules need). Icons: each icon in the two `config*.jsonc` is a `<span size='large' font_family='JetBrainsMono Nerd Font'>`, so they keep the Nerd Font whatever the text font is |
| Super+D launcher (fuzzel) | `~/.config/fuzzel/fuzzel.ini`, `[main]` | `font=Eternal UI:size=14` |
| Sway titles / swaynag | `~/.config/sway/config` | `font pango:Eternal UI Bold 11` (caps-only weight) |
| Hyprland (group bars, dialogs) | `~/.config/hypr/hyprland.lua`, `groupbar` and `misc` blocks | `font_family = "Eternal UI"`, group bar in the bold (caps-only) weight |
| Lock screen (hyprlock) | `~/.config/hypr/hyprlock.conf` | `$font` (fields) and `$hfont` (header, clock) at the top, `font_size` per label |
| Notifications (mako) | `~/.config/mako/config` | `font=Eternal UI 12` |
| Tabby | Tabby settings, Appearance | GUI setting, not a file managed here |
| Login screen (SDDM) | `Themes/doom.conf` | `Font` (fields, buttons) and `HeaderFont` (header text and clock, bold) |

The DOOM fonts: `Eternal UI` and `Eternal UI 2` regular weights are condensed sans faces with real lowercase; both bold weights are caps-only (lowercase renders as capitals, `Eternal UI 2` bold has the slashed O), so they are used only for title bars, workspace numbers, the clock and headers. GTK and Qt apps stay on IBM Plex Sans.

After editing: `swaymsg reload` (Sway + bar), Hyprland reloads on save (bar needs a restart, see below),
`makoctl reload` for mako; fuzzel reads its file on every launch.

## App theming (Qt and GTK)

Plasma used to supply the Qt platform theme (`plasma-integration`); without it Qt apps such as
pcmanfm-qt have no icon theme, style or font. The replacement is qt6ct (Qt6) and qt5ct (Qt5):

- Packages: `sudo dnf install qt6ct qt5ct` (optional: `kvantum` for SVG-based Qt styles, `papirus-icon-theme`).
- `QT_QPA_PLATFORMTHEME=qt6ct` is exported in `~/.zprofile` and set in `hyprland.lua`; Qt5 apps automatically use qt5ct with the same value.
- Run `qt6ct` (and `qt5ct`) to pick style, icon theme, palette and fonts with a GUI; changes apply to newly started apps.
  The Breeze Qt style (`plasma-breeze-qt6`) is still installed. The Catppuccin palette is in `~/.config/qt6ct/colors/`.
- Icon themes available: `breeze`, `breeze-dark` (system) and Tela, WhiteSur, McMojave-circle, candy-icons and others in `~/.local/share/icons/`.
  The same names work in GTK's `gtk-icon-theme-name` and qt6ct's `icon_theme`, so both toolkits can share one icon set.
- GTK apps read `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini` (currently Adwaita theme, breeze icons, IBM Plex Sans 13).
  `nwg-look` (`sudo dnf install nwg-look`) is a GUI for these files. Themes go in `~/.themes/` or `/usr/share/themes/`.
- Qt apps read qt6ct settings only at startup, and pcmanfm-qt is single-instance: after changing anything, `pkill pcmanfm-qt` (or quit the app fully) and relaunch.
- If a Breeze-styled app ever shows a light menu bar/toolbar again, some KDE app has recreated `~/.config/kdeglobals`; delete it, or switch the style in qt6ct to Fusion or Kvantum, which never read it.
- Default apps for file types (e.g. folders opening in git-cola) are in `~/.config/mimeapps.list`; fix with `xdg-mime default pcmanfm-qt.desktop inode/directory`.
- Cursor: `XCURSOR_SIZE` / `HYPRCURSOR_SIZE` in `hyprland.lua`, `seat * xcursor_theme` in the Sway config, `gtk-cursor-theme-name` for GTK apps. Themes in `~/.icons/`.

## Handy commands

| Task | Command |
|---|---|
| Validate Sway config | `sway -C --unsupported-gpu` |
| Reload Sway (also restarts Waybar) | `swaymsg reload` |
| Validate Hyprland config | `Hyprland --verify-config` |
| Reload Hyprland | automatic on save, or `hyprctl reload` |
| Restart Waybar under Hyprland | `pkill waybar; setsid waybar -c ~/.config/waybar/config-hyprland.jsonc >/dev/null 2>&1 &` |
| Monitor names / descriptions | `hyprctl monitors` or `swaymsg -t get_outputs` |
| Try a monitor layout (not persistent) | `wdisplays` |
| Pick a wallpaper | `waypaper` (Super+D), or `waypaper --wallpaper ~/Pictures/Wallpapers/x.jpg` |

## Wallpapers

- `waypaper` is the picker (GTK). Folder: `~/Pictures/Wallpapers`, backend: `awww` (the swww successor). Both settings and the last picked image live in `~/.config/waypaper/config.ini`.
- Persistence: both compositors autostart `awww-daemon` and then `waypaper --restore`, which reapplies the last pick. Hyprland no longer starts hyprpaper and Sway's `output * bg` line is commented out, so only one wallpaper daemon runs.
- Per-monitor images: set `monitors` in waypaper's settings (default `All`).

## Login screen (SDDM)

- Theme: `sddm-astronaut-theme` (Qt6 QML, github.com/Keyitdev/sddm-astronaut-theme) with a custom `doom` preset. Master copy in `~/.config/sddm-doom-theme/`, installed copy in `/usr/share/sddm/themes/sddm-astronaut-theme/`.
- Install or reinstall: `sudo sh ~/.config/sddm-doom-theme/install-sddm-theme.sh` (copies the theme, installs its fonts, writes `/etc/sddm.conf.d/10-theme.conf` and `20-users.conf`).
- Username is prefilled with the last login and the cursor starts in the password field (`ForceLastUser`, `PasswordFocus` in the preset, `RememberLastUser` in SDDM).
- Fonts: fan-made DOOM Eternal UI fonts (`Eternal UI`, `Eternal UI 2`) in `~/.fonts/doom/` for the session and in the theme's `Fonts/` dir (the install script puts them in `/usr/share/fonts/` for the greeter).
- Lock screen matches: `~/.config/hypr/hyprlock.conf` (Hyprland) and `~/.config/swaylock/config` (Sway, `$lock` is plain `swaylock -f`) use the same wallpaper, font and colours.
- Eternal-style shapes: fields, login button, dropdowns and power buttons are drawn by `Components/EternalShape.qml` (a QtQuick.Shapes polygon with per-corner chamfers: the fields are elongated hexagons, the login button and dropdown highlight are parallelograms, the popups are cards with four small cuts). The preset's colours follow the Eternal menu: olive panels (`LoginFieldBackgroundColor`), light-green outline (`FieldBorderColor`, a key added to the theme; `HighlightBorderColor` when focused) and orange for the active login button (`LoginButtonBackgroundColor`). Other presets ignore the new key and fall back to no outline.
- hyprlock can only draw rectangles, so its chamfered panels are PNGs in `~/.config/hypr/` (`eternal-input.png`, `eternal-layout.png`) rendered by `tools/eternal-panel.py` in the repo; the `input-field` is transparent on top of the image and only draws the dots and the red failure outline. swaylock has no image widgets, so the Sway lock screen keeps its plain ring indicator.
- Change the look: edit `Themes/doom.conf` in the installed copy (`Background=` takes png/jpg/gif/mp4/webm relative to the theme dir, `HeaderText`, colours, `Font`). Preview without logging out: `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/sddm-astronaut-theme`.

## Windows programs (Steam/Proton, Wine)

- Proton games get the X11 class `steam_app_<appid>`, Wine programs `<name>.exe`. Both compositors send anything matching `^(steam_app_\d+|.*\.exe)$` to workspace 2, and workspace 2 is pinned to the Lenovo 1440p monitor whenever it is connected (`hl.workspace_rule` / `workspace 2 output` rules next to the other assigns).
- Check a game's class with `hyprctl clients` or `swaymsg -t get_tree | grep class`.

## Notes

- Monitor layout lives in the config, not in wdisplays. Externals are matched by make/model/serial
  (`desc:` in Hyprland, quoted string in Sway), so home (Lenovo + HP) and office (Dell 3119RP3, AOC, Dell 85LJRP3) are
  both listed and only the connected ones apply; unknown monitors fall through to auto placement.
- Laptop panel (eDP-1): on at home and on the road, off at the office. Hyprland does this in Lua (`update_laptop_panel` in
  `hyprland.lua`: checks `hl.get_monitors()` for an office description, re-runs on `monitor.added`/`monitor.removed`).
  Sway cannot do conditionals, so kanshi does it there: profiles in `~/.config/kanshi/config`, started by `exec kanshi`
  in the Sway config (`sudo dnf install kanshi`). Do not run kanshi under Hyprland; the two would fight on reload.
- Hyprland Lua gotchas found: a monitor rule containing `disabled = false` is silently ignored (use a rule without the key
  to enable), and the catch-all `output = ""` rule must be the last `hl.monitor` call.
- Network: no nm-applet/tray icon; the bar's `network` module shows a Nerd Font wifi/ethernet icon (wifi: SSID, ethernet: IP address) and opens `nm-connection-editor` on click.
- Performance metrics: one gauge icon (`custom/perf`), hover for a popup with CPU temp, CPU usage, memory, a rule, then GPU temp, usage and VRAM, one per line. Data comes from `~/.config/waybar/scripts/perf.sh` (coretemp hwmon, /proc/stat sampled over 0.5 s, /proc/meminfo, nvidia-smi) every 3 s; the icon turns red above 80% CPU. Edit the printf at the end of the script to change the lines.
- Super+W under Hyprland: `tab_workspace()` in `hyprland.lua` groups every tiled window on the current workspace into one group (i3 `layout tabbed`); pressing it on a grouped window dissolves the group. Tab strip styling is the `group.groupbar` block (Iosevka 13, height 24, Catppuccin colours). New windows opened while a group is focused join it (`auto_group`).
- Keyboard layout: Super+Space toggles us/se (Alt+Super+S / Alt+Super+U still select one directly); clicking the bar's keyboard icon toggles too. The Hyprland language module is pinned to `at-translated-set-2-keyboard` (built-in keyboard) because Hyprland makes the last-connected input device 'main' and the Bluetooth headset then reports no layout. The old Super+Space actions (Hyprland cycle_next, Sway focus mode_toggle) moved to Super+Ctrl+Space.
- Bar workspaces are per monitor (`all-outputs: false`); each screen's bar shows only its own workspaces.
- Hyprland's example config for the installed version is at `/usr/share/hypr/hyprland.lua`, and the Lua API
  stub (every valid field) is `/usr/share/hypr/stubs/hl.meta.lua`. The online wiki tracks git and can be ahead.
- Waybar icons are stored as `\u` escapes because private-use glyphs get stripped by some tools.
- App launcher buttons on the bar are the `custom/app-*` modules in both `config*.jsonc` (an icon, a `tooltip-format` and an `on-click` command),
  listed in `modules-left` right after the workspaces, and styled by the `#custom-app-*` block in `style.css`. To add one: copy a module,
  give it a new name, add the name to `modules-left` in both files and to the CSS selector list. Nerd Font glyph codes: https://www.nerdfonts.com/cheat-sheet
  Launcher colours are per-module rules in the same CSS block: Firefox `#ff7139`, VS Code Insiders `#24bfa5`, Claude `#d97757`, Steam `#66c0f4`;
  terminal and folder use `@subtext` and turn `@text` on hover. A new launcher without its own rule inherits the grey.
- Xwayland runs as a child of the compositor for X11-only apps; Tabby, Emacs and Claude are native Wayland.
- Hyprland has `xwayland.force_zero_scaling = true`: X11 apps (all Proton/Steam games) see the laptop panel at its real 2560x1600
  instead of the scaled 2048x1280, so games render sharp there. Non-game X11 apps look small on that panel as a result. Sway has no
  equivalent option and always upscales Xwayland windows on a scaled output, so game on Hyprland or on an unscaled external monitor.
