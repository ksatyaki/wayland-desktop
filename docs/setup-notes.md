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
| `~/.config/waybar/config.jsonc`, `config-hyprland.jsonc` | Bar entry for Sway / Hyprland: a single bar for every output, including the module file below |
| `~/.config/waybar/modules-sway.jsonc` | The modules themselves for Sway: bottom position, hover volume slider, icons written as `\u` escapes |
| `~/.config/waybar/modules-hyprland.jsonc` | Same modules using the `hyprland/*` workspace, window, submap and language modules |
| `~/.config/waybar/style.css` | Solid Catppuccin Mocha stylesheet, workspace highlight for both compositors, slider styling |
| `~/.config/waybar/scripts/brightness.sh` | Per-monitor brightness for the bar module and the Fn keys (backlight or DDC/CI) |
| `~/.config/waybar/scripts/perf.sh`, `gpu.sh` | Data for the metrics gauge (CPU temp and usage, memory, GPU temp, usage and VRAM via nvidia-smi) |
| `~/.config/mako/config` | Notification daemon in the same palette |
| `~/.config/fuzzel/fuzzel.ini` | Super+D launcher: font, size, DOOM palette (same colours as the login theme's `doom.conf`) |
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
- Office: the three monitors hang off the dock (left Dell on its HDMI port, AOC and right Dell on DisplayPort) and reach the
  laptop as DP-3/4/5, so connector names say nothing about the layout; the serial matching does the work. The AOC rule asks for
  the highest 1440p refresh rate the monitor offers over the current link, capped at `AOC_MAX_HZ` = 144 (`best_mode()` in
  `hyprland.lua` reads `available_modes`). It advertises 180 Hz over the dock's DisplayPort, but there Hyprland modesets fine
  and the monitor shows "no signal". 144 Hz works from a fresh boot; switching 180 -> 120 -> 144 live on 2026-10-07 left
  Hyprland's main thread in the DRM atomic-commit ioctl in D state and froze the session (NVIDIA), so a reboot was needed.
  Over the laptop's own HDMI port 144 Hz fails the modeset and Hyprland falls back to 60 Hz. The same cap sits in
  `single-monitor.sh` (`max_hz`, override with `SINGLE_MONITOR_MAX_HZ`).
- Laptop panel (eDP-1): on at home and on the road, off at the office. Hyprland does this in Lua (`docked()` in `hyprland.lua`
  checks `hl.get_monitors()` for an office description). Everything the monitors block derives from the connected monitors is
  folded into `layout_key()`; on `monitor.added`/`monitor.removed` the config reloads only when that key changed, because
  monitor rules pushed at runtime do not always re-enable a disabled output while rules applied at load do.
  Sway cannot do conditionals, so kanshi does it there: profiles in `~/.config/kanshi/config`, started by `exec kanshi`
  in the Sway config.
- Super+P (Hyprland): `~/.config/hypr/scripts/single-monitor.sh` toggles between the site layout and a single external monitor:
  the external with the highest resolution, then refresh rate up to 144 Hz (`hyprctl -j monitors all`), at that mode at 0x0, every other
  output off including the laptop panel. The pick is written to `$XDG_RUNTIME_DIR/hypr-single-monitor` and `hyprctl reload`
  applies it, since `hyprland.lua` reads that file first and skips the site layout while it exists. On hotplug in single mode
  the config calls `single-monitor.sh refresh`, which re-picks (a bigger monitor takes over; when the last external goes the
  flag is removed and the site layout returns). After every change the script sends Waybar SIGUSR2 so it rebuilds its
  per-output bars, or starts it again if it died (the bar has vanished once after a toggle), and on the way back it moves the
  workspaces to the monitors they were on before (map saved in `hypr-single-monitor.workspaces`). With no external connected
  the bind only shows a notification. Changing the AOC's refresh rate live is where the session froze; prefer a reboot for that.
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
- Brightness is per monitor. `config*.jsonc` holds a single bar entry with no `"output"` key, so waybar puts it on every
  output, including connectors that did not exist when it started. Waybar exports `WAYBAR_OUTPUT_NAME` to a custom module's
  `exec` (not to its scroll commands), so the brightness module runs `brightness.sh status self` and the scroll commands use
  `focused`, which is the monitor under the cursor. Do not go back to one bar per connector name: a dock's MST monitors come
  back as new connectors after a replug (`DP-2`..`DP-4` became `DP-6`..`DP-8` on 2026-10-08) and lose their bar, since an
  output with no matching entry gets none. An `"output"` **array** is a whitelist, so `["!DP-1", ...]` is not a catch-all
  either; negation works only as a bare string holding one name. Verified on waybar 0.15.
- `scripts/brightness.sh status|set <output>` picks the backend per monitor and caches it in `$XDG_RUNTIME_DIR/brightness`:
  a panel under `/sys/class/backlight` (`brightnessctl`), otherwise the i2c bus that `ddcutil detect` reports for that DRM
  connector — matched on `DRM_connector` first, on the EDID serial otherwise. A monitor that answers neither prints nothing,
  which hides the module on that bar. Scrolling and the Fn keys
  both move in linear 5% steps, so the number on the bar is the value written to the hardware.
- DDC/CI is slow (~0.3 s per call), so the bar shows a cached value, re-read from the monitor every 5 min, and a scroll
  burst is coalesced behind a `flock` into a single write — the bar updates immediately (`pkill -RTMIN+8 waybar`) and only
  the final position goes out over i2c.
- External monitor brightness needs read/write on `/dev/i2c-*`. `sudo dnf install ddcutil` ships
  `/usr/lib/udev/rules.d/60-ddcutil-i2c.rules`, which tags the GPU's i2c buses `uaccess` so logind gives the active session an
  ACL on them — no `i2c` group on Fedora. The rule only applies to device nodes created after it landed, so after installing:
  `sudo udevadm control --reload-rules && sudo udevadm trigger -s i2c-dev -s dri` (a reboot does the same). `ddcutil detect`
  then lists the monitors that answer; laptop panels never do ("Invalid display"), and monitors that do not keep a bar without
  the brightness module.
- The Fn brightness keys follow the focused monitor, not the laptop panel.
- Waybar icons are stored as `\u` escapes because private-use glyphs get stripped by some tools.
- Keyboard layout: Super+Space toggles us/se (Alt+Super+S / Alt+Super+U still select one directly); clicking the bar's keyboard icon toggles too. The Hyprland language module is pinned to `at-translated-set-2-keyboard` (built-in keyboard) because Hyprland makes the last-connected input device 'main' and a Bluetooth headset then reports no layout. The old Super+Space actions (Hyprland cycle_next, Sway focus mode_toggle) moved to Super+Ctrl+Space.

## Windows and groups

- Super+W under Hyprland: `tab_workspace()` in `hyprland.lua` groups every tiled window on the current workspace into one group (i3 `layout tabbed`); pressing it on a grouped window dissolves the group. Tab strip styling is the `group.groupbar` block. New windows opened while a group is focused join it (`auto_group`).
- Xwayland runs as a child of the compositor for X11-only apps; Tabby, Emacs and Claude are native Wayland.
- Hyprland's example config for the installed version is at `/usr/share/hypr/hyprland.lua`, and the Lua API
  stub (every valid field) is `/usr/share/hypr/stubs/hl.meta.lua`. The online wiki tracks git and can be ahead.

## Windows programs (Steam/Proton, Wine)

- Proton games get the X11 class `steam_app_<appid>`, Wine programs `<name>.exe`. Both compositors send anything matching `^(steam_app_\d+|.*\.exe)$` to the workspace pinned to the Lenovo 1440p monitor: workspace 1 in Hyprland (workspace 2 is pinned to the HP), workspace 2 in Sway (`hl.workspace_rule` / `workspace 2 output` rules next to the other assigns).
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
| Restart Waybar under Hyprland | `systemctl --user restart waybar.service` (a memory-capped user service tied to hyprland-session.target; `journalctl --user -u waybar` for its output) |
| Reload mako | `makoctl reload` (fuzzel reads its file on every launch) |
| Monitor names / descriptions | `hyprctl monitors` or `swaymsg -t get_outputs` |
| Try a monitor layout (not persistent) | `wdisplays` |
| Pick a wallpaper | `waypaper` (Super+D), or `waypaper --wallpaper ~/Pictures/Wallpapers/x.jpg` |
