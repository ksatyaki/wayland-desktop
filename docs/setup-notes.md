# Setup notes

Set up on 2026-09-11 on Fedora 44, ported from an old `~/.i3/config`. Both compositors share the same
keybindings (i3-style: Super as mod, j/k/l/; for focus), the same Waybar bar, and the same
Catppuccin Mocha palette. Fonts and app theming are in [fonts-and-theming.md](fonts-and-theming.md),
the login and lock screens in [login-and-lock-screen.md](login-and-lock-screen.md).

## Config files

### Sway

| File | Purpose |
|---|---|
| `~/.config/sway/config` | Window manager: keybindings ported from i3, gaps, monitor layout by make/model/serial, media keys, floating rule for pavucontrol, autostart (waybar, mako, swayidle, polkit agent, terminal, Claude, VS Code Insiders) |
| `~/.config/swaylock/config` | Lock screen (`$lock` in the Sway config is plain `swaylock -f`) |
| `~/.config/kanshi/config` | Monitor profiles (laptop / home / office) for Sway, incl. disabling eDP-1 at the office |
| `/usr/local/share/wayland-sessions/sway-nvidia.desktop` | SDDM session entry that launches Sway with `--unsupported-gpu` (required on the proprietary NVIDIA driver) |

### Bar and notifications (shared)

| File | Purpose |
|---|---|
| `~/.config/waybar/config.jsonc` | Bar modules for Sway, bottom position, hover volume slider, icons written as `\u` escapes |
| `~/.config/waybar/config-hyprland.jsonc` | Same bar using the `hyprland/*` workspace, window, submap and language modules |
| `~/.config/waybar/style.css` | Solid Catppuccin Mocha stylesheet, workspace highlight for both compositors, slider styling |
| `~/.config/waybar/scripts/perf.sh`, `gpu.sh` | Data for the metrics gauge (CPU temp and usage, memory, GPU temp, usage and VRAM via nvidia-smi) |
| `~/.config/mako/config` | Notification daemon in the same palette |
| `~/.config/fuzzel/fuzzel.ini` | Super+D launcher: font, colours, size |
| `~/.config/waypaper/config.ini` | Wallpaper: folder, backend (awww) and last picked image; written by waypaper |

### Hyprland

| File | Purpose |
|---|---|
| `~/.config/hypr/hyprland.lua` | Compositor config in the Hyprland >= 0.56 Lua format: same keybindings, monitor layout, NVIDIA and Electron environment, window rules, autostart |
| `~/.config/hypr/hypridle.conf` | Lock after 10 minutes, screen off after 15, lock before sleep |
| `~/.config/hypr/hyprlock.conf` | Lock screen, with `eternal-input.png` and `eternal-layout.png` as the chamfered panels |

### App theming, system and keyring

| File | Purpose |
|---|---|
| `~/.config/qt6ct/qt6ct.conf`, `~/.config/qt5ct/qt5ct.conf` | Qt app look: Fusion style, breeze-dark icons, Catppuccin palette (`colors/Catppuccin-Mocha.conf`), fonts. Edit with the `qt6ct` / `qt5ct` GUI |
| `~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini` | GTK app look: theme, icon theme, font, cursor |
| `~/.config/mimeapps.list` | Default apps per file type (folders open in pcmanfm-qt) |
| `~/.zprofile` | Exports `QT_QPA_PLATFORMTHEME=qt6ct` for the whole session (SDDM starts the session via a zsh login shell); Hyprland also sets it in `hyprland.lua` |
| `~/.config/kdeglobals`, `kdedefaults/`, `Trolltech.conf`, `xsettingsd/`, `kwinrc`, `plasma*` ... | Deleted on purpose by `tools/purge-kde-config.sh`: leftovers of a Plasma install that the Breeze Qt style and kde-gtk-config keep reading, overriding the qt6ct/GTK settings |
| `/etc/sddm.conf.d/10-theme.conf`, `20-users.conf` | SDDM login theme and remember-last-user settings |
| `~/.config/sddm-doom-theme/` | Master copy of the login theme, DOOM preset and its install script |
| `~/.local/share/keyrings/default` | Not in the repo. Contains `login`: marks the `login` keyring as the default for Secret Service apps (Claude, browsers). gnome-keyring is unlocked at login by the PAM stack in `/etc/pam.d/sddm` (already present on Fedora) |

## Not files, but needed to reproduce

- Hyprland packages come from the `lionheartp/Hyprland` COPR on Fedora (Hyprland was retired from Fedora proper):
  `sudo dnf copr enable lionheartp/Hyprland`. Ubuntu/Debian package an older Hyprland that cannot read the Lua config; build from source.
- The full package lists per component and distro are in the README's Dependencies table; `./install.sh --packages` installs them.
- On Fedora, Plasma was removed but `kwin`, `sddm-wayland-plasma`, `kde-settings-sddm` and `plasma-keyboard` are kept so SDDM's
  greeter keeps running on KWin. They are marked `dnf mark user` so `dnf autoremove` leaves them alone.
- kanshi is only used under Sway; do not run it under Hyprland (the two would fight on reload).

## Monitors

- Monitor layout lives in the config, not in wdisplays. Externals are matched by make/model/serial
  (`desc:` in Hyprland, quoted string in Sway), so home (Lenovo + HP) and office (Dell, AOC, Dell) are
  both listed and only the connected ones apply; unknown monitors fall through to auto placement.
  The entries are the author's monitors: get yours from `hyprctl monitors` or `swaymsg -t get_outputs` and replace them.
- Laptop panel (eDP-1): on at home and on the road, off at the office. Hyprland does this in Lua (`update_laptop_panel` in
  `hyprland.lua`: checks `hl.get_monitors()` for an office description, re-runs on `monitor.added`/`monitor.removed`).
  Sway cannot do conditionals, so kanshi does it there: profiles in `~/.config/kanshi/config`, started by `exec kanshi`
  in the Sway config.
- Hyprland Lua gotchas found: a monitor rule containing `disabled = false` is silently ignored (use a rule without the key
  to enable), and the catch-all `output = ""` rule must be the last `hl.monitor` call.
- Bar workspaces are per monitor (`all-outputs: false`); each screen's bar shows only its own workspaces.
- Hyprland has `xwayland.force_zero_scaling = true`: X11 apps (all Proton/Steam games) see the laptop panel at its real 2560x1600
  instead of the scaled 2048x1280, so games render sharp there. Non-game X11 apps look small on that panel as a result. Sway has no
  equivalent option and always upscales Xwayland windows on a scaled output, so game on Hyprland or on an unscaled external monitor.

## Bar

- Network: no nm-applet/tray icon; the bar's `network` module shows a Nerd Font wifi/ethernet icon (wifi: SSID, ethernet: IP address) and opens `nm-connection-editor` on click.
- Performance metrics: one gauge icon (`custom/perf`), hover for a popup with CPU temp, CPU usage, memory, a rule, then GPU temp, usage and VRAM, one per line. Data comes from `~/.config/waybar/scripts/perf.sh` (coretemp hwmon, /proc/stat sampled over 0.5 s, /proc/meminfo, nvidia-smi) every 3 s; the icon turns red above 80% CPU. Edit the printf at the end of the script to change the lines.
- App launcher buttons on the bar are the `custom/app-*` modules in both `config*.jsonc` (an icon, a `tooltip-format` and an `on-click` command),
  listed in `modules-left` right after the workspaces, and styled by the `#custom-app-*` block in `style.css`. To add one: copy a module,
  give it a new name, add the name to `modules-left` in both files and to the CSS selector list. Nerd Font glyph codes: https://www.nerdfonts.com/cheat-sheet
  Launcher colours are per-module rules in the same CSS block: Firefox `#ff7139`, VS Code Insiders `#24bfa5`, Claude `#d97757`, Steam `#66c0f4`;
  terminal and folder use `@subtext` and turn `@text` on hover. A new launcher without its own rule inherits the grey.
- Waybar icons are stored as `\u` escapes because private-use glyphs get stripped by some tools.
- Keyboard layout: Super+Space toggles us/se (Alt+Super+S / Alt+Super+U still select one directly); clicking the bar's keyboard icon toggles too. The Hyprland language module is pinned to `at-translated-set-2-keyboard` (built-in keyboard) because Hyprland makes the last-connected input device 'main' and a Bluetooth headset then reports no layout. The old Super+Space actions (Hyprland cycle_next, Sway focus mode_toggle) moved to Super+Ctrl+Space.

## Windows and groups

- Super+W under Hyprland: `tab_workspace()` in `hyprland.lua` groups every tiled window on the current workspace into one group (i3 `layout tabbed`); pressing it on a grouped window dissolves the group. Tab strip styling is the `group.groupbar` block. New windows opened while a group is focused join it (`auto_group`).
- Xwayland runs as a child of the compositor for X11-only apps; Tabby, Emacs and Claude are native Wayland.
- Hyprland's example config for the installed version is at `/usr/share/hypr/hyprland.lua`, and the Lua API
  stub (every valid field) is `/usr/share/hypr/stubs/hl.meta.lua`. The online wiki tracks git and can be ahead.

## Windows programs (Steam/Proton, Wine)

- Proton games get the X11 class `steam_app_<appid>`, Wine programs `<name>.exe`. Both compositors send anything matching `^(steam_app_\d+|.*\.exe)$` to workspace 2, and workspace 2 is pinned to the Lenovo 1440p monitor whenever it is connected (`hl.workspace_rule` / `workspace 2 output` rules next to the other assigns).
- Check a game's class with `hyprctl clients` or `swaymsg -t get_tree | grep class`.

## Wallpapers

- `waypaper` is the picker (GTK). Folder: `~/Pictures/Wallpapers`, backend: `awww` (the swww successor). Both settings and the last picked image live in `~/.config/waypaper/config.ini`.
- Persistence: both compositors autostart `awww-daemon` and then `waypaper --restore`, which reapplies the last pick. Hyprland does not start hyprpaper and Sway's `output * bg` line is commented out, so only one wallpaper daemon runs.
- Per-monitor images: set `monitors` in waypaper's settings (default `All`).

## Handy commands

| Task | Command |
|---|---|
| Validate Sway config | `sway -C --unsupported-gpu` |
| Reload Sway (also restarts Waybar) | `swaymsg reload` |
| Validate Hyprland config | `Hyprland --verify-config` |
| Reload Hyprland | automatic on save, or `hyprctl reload` |
| Restart Waybar under Hyprland | `pkill waybar; setsid waybar -c ~/.config/waybar/config-hyprland.jsonc >/dev/null 2>&1 &` |
| Reload mako | `makoctl reload` (fuzzel reads its file on every launch) |
| Monitor names / descriptions | `hyprctl monitors` or `swaymsg -t get_outputs` |
| Try a monitor layout (not persistent) | `wdisplays` |
| Pick a wallpaper | `waypaper` (Super+D), or `waypaper --wallpaper ~/Pictures/Wallpapers/x.jpg` |
