-- Hyprland config (Lua, Hyprland >= 0.56) — ported from the old ~/.i3/config
-- Docs: https://wiki.hypr.land/configuring/core/   Stubs for editor completion: /usr/share/hypr/stubs

local mod      = "SUPER"
local terminal = "alacritty"
local menu     = "fuzzel"
local lock     = "pidof hyprlock || hyprlock"
local brightness = os.getenv("HOME") .. "/.config/waybar/scripts/brightness.sh"

------------------------------------------------------------------ monitors
-- Two layouts. Both are decided here at config load: monitor rules applied at load work reliably, rules pushed later at
-- runtime do not always re-enable a disabled output, so every layout change goes through `hyprctl reload` and this block.
--  * site layout: home or office, by whichever monitors are connected. Externals are matched by make/model/serial ("desc:"
--    from hyprctl monitors), so the port they hang off does not matter; unknown monitors fall through to the "auto" rule
--    at the end (which must stay LAST: first matching rule wins).
--  * single monitor (Super+P, scripts/single-monitor.sh): one external at its highest resolution and refresh rate,
--    every other output off. The script writes its pick to $XDG_RUNTIME_DIR/hypr-single-monitor and reloads; while that
--    file exists it is applied instead of the site layout.
local single_monitor_file = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hypr-single-monitor"
local single_monitor_sh   = os.getenv("HOME") .. "/.config/hypr/scripts/single-monitor.sh"
local function read_single_monitor()   -- line 1: "<output> <WxH@Hz>", then one output name per line to disable
    local f = io.open(single_monitor_file)
    if not f then return nil end
    local pick = { disable = {} }
    for line in f:lines() do
        if not pick.name then pick.name, pick.mode = line:match("^(%S+)%s+(%S+)")
        elseif line ~= "" then pick.disable[#pick.disable + 1] = line end
    end
    f:close()
    return pick.name and pick or nil
end

-- "WxH@Hz" with the highest refresh rate (at most `max_hz`) the connected monitor whose description contains `desc` offers at
-- that resolution; `fallback` when it is not connected. hl.get_monitors() lists enabled monitors only.
local function best_mode(desc, w, h, fallback, max_hz)
    local best
    for _, m in ipairs(hl.get_monitors()) do
        if m.description and m.description:find(desc, 1, true) and type(m.available_modes) == "table" then
            for _, mode in ipairs(m.available_modes) do
                if mode.width == w and mode.height == h and mode.refresh_rate <= (max_hz or math.huge) + 0.5
                   and (not best or mode.refresh_rate > best) then best = mode.refresh_rate end
            end
        end
    end
    return best and string.format("%dx%d@%d", w, h, math.floor(best + 0.5)) or fallback
end

-- laptop panel (eDP-1): on at home and on the road, off whenever an office monitor is connected
local office_monitors = { "AOC Q27G42XE", "DELL U2422H" }
local function docked()
    for _, m in ipairs(hl.get_monitors()) do
        for _, d in ipairs(office_monitors) do
            if m.description and m.description:find(d, 1, true) then return true end
        end
    end
    return false
end
-- everything this block derives from the connected monitors; when a hotplug changes it, the config is reloaded
-- The AOC advertises up to 180 Hz over the dock's DisplayPort, but at 180 Hz the modeset succeeds and the monitor shows
-- "no signal". 144 Hz works from a fresh boot; switching to it live right after the 180 Hz attempt hung the compositor in
-- the DRM atomic commit (NVIDIA, 2026-10-07), so change rates by reload only when nothing is already wrong. Over the laptop's
-- own HDMI port 144 Hz fails the modeset and falls back to 60 Hz; 120 Hz works there.
local AOC_MAX_HZ = 144
local function layout_key() return tostring(docked()) .. " " .. best_mode("AOC Q27G42XE", 2560, 1440, "preferred", AOC_MAX_HZ) end
local loaded_layout_key = layout_key()

local single_monitor = read_single_monitor()
if single_monitor then
    hl.monitor({ output = single_monitor.name, mode = single_monitor.mode, position = "0x0", scale = 1 })
    for _, name in ipairs(single_monitor.disable) do hl.monitor({ output = name, disabled = true }) end
else
    -- home: laptop panel left (bottom-aligned), Lenovo, HP
    hl.monitor({ output = "desc:Lenovo Group Limited G27q-20 U63330HD", mode = "2560x1440@120", position = "2048x0",   scale = 1 })  -- Lenovo 2560x1440, 120 Hz (its EDID-preferred mode is only 60 Hz)
    hl.monitor({ output = "desc:HP Inc. HP E24u G5 CN43172GTD",        mode = "preferred", position = "4608x360", scale = 1 })  -- HP 1920x1080
    -- office: Dell, AOC, Dell, bottom-aligned, laptop panel off. All three hang off the dock (left Dell on its HDMI port, AOC
    -- and right Dell on DisplayPort) and reach the laptop as DP-3/4/5, hence the serial matching. The AOC runs at the
    -- highest 1440p rate its link offers up to AOC_MAX_HZ (its EDID-preferred mode is 60 Hz).
    hl.monitor({ output = "desc:Dell Inc. DELL U2422H 3119RP3",         mode = "preferred", position = "0x360",    scale = 1 })  -- Dell 1920x1080 (left, dock HDMI)
    hl.monitor({ output = "desc:AOC Q27G42XE 1O0R4HA008572",            mode = best_mode("AOC Q27G42XE", 2560, 1440, "preferred", AOC_MAX_HZ), position = "1920x0", scale = 1 })  -- AOC 2560x1440
    hl.monitor({ output = "desc:Dell Inc. DELL U2422H 85LJRP3",         mode = "preferred", position = "4480x360", scale = 1 })  -- Dell 1920x1080 (right)

    if docked() then
        hl.monitor({ output = "eDP-1", disabled = true })
    else
        hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x160", scale = 1.25 }) -- 2560x1600 -> 2048x1280 logical
    end
end
-- XWayland marks no output as RandR "primary", so Wine/Proton games enumerate the first X output (here the HP 1080p)
-- and offer only its modes. Make the monitor that hosts workspace 1 (where games open, see windows-apps-ws1) the primary.
local set_x11_primary = "sleep 2; m=$(hyprctl -j workspaces | jq -r '.[] | select(.id==1) | .monitor'); "
                     .. "[ -n \"$m\" ] && xrandr --output \"$m\" --primary"
local function on_monitor_change()
    if read_single_monitor() then
        hl.exec_cmd(single_monitor_sh .. " refresh")   -- re-pick; the script reloads only when the pick changed
    elseif layout_key() ~= loaded_layout_key then
        hl.exec_cmd("hyprctl reload")
    end
    hl.exec_cmd(set_x11_primary)
end
hl.on("monitor.added", function()
    on_monitor_change()
    -- awww-daemon remembers the wallpaper per connector name, and a dock replug brings its monitors back under new
    -- names (DP-2..4 became DP-6..8), which it then leaves black: re-apply the wallpaper picked in waypaper.
    hl.exec_cmd("sleep 1 && waypaper --restore")
end)
hl.on("monitor.removed", on_monitor_change)
hl.monitor({ output = "",         mode = "preferred", position = "auto",   scale = "auto" }) -- anything else (must stay LAST: first matching rule wins)

------------------------------------------------------------------ environment
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
-- proprietary NVIDIA driver (see https://wiki.hypr.land/nvidia/)
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
-- run Electron apps (Tabby, Chrome, ...) and toolkits natively on Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct") -- Qt style/icons/fonts from ~/.config/qt6ct (also in ~/.zprofile for Sway)
-- FreeType: v35 TrueType interpreter (full horizontal stem snapping, the pre-2016 look) plus CFF
-- stem darkening. Pairs with ~/.config/fontconfig/fonts.conf (subpixel RGB, hintfull, no autohint).
-- Must live here: Hyprland runs in the session scope, not a systemd user unit, so ~/.config/
-- environment.d is never read. Also in ~/.zprofile for Sway.
hl.env("FREETYPE_PROPERTIES", "truetype:interpreter-version=35 cff:no-stem-darkening=0")
-- IBus input method (Tamil phonetic via m17n, engines picked in ibus-setup). Every toolkit talks to the daemon
-- started in the autostart block below; XMODIFIERS covers XWayland/X11 apps.
-- Super+space is taken by the us/se xkb toggle below, so the IBus engine switch is Alt+Shift+space:
--   gsettings set org.freedesktop.ibus.general.hotkey triggers "['<Alt><Shift>space']"
hl.env("GTK_IM_MODULE", "ibus")
hl.env("QT_IM_MODULE", "ibus")
hl.env("XMODIFIERS", "@im=ibus")
hl.env("SDL_IM_MODULE", "ibus")
hl.env("GLFW_IM_MODULE", "ibus")

------------------------------------------------------------------ look & feel
hl.config({
    xwayland = {
        force_zero_scaling = true,   -- X11 apps (Proton games) see the panel's full 2560x1600, not the scaled 2048x1280
    },
    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 2,
        col = {
            active_border   = "rgba(89b4faee)",   -- Catppuccin Mocha blue
            inactive_border = "rgba(313244aa)",
        },
        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    group = {
        auto_group = true,                     -- windows opened while a group is focused join it
        col = {
            border_active          = "rgba(89b4faee)",
            border_inactive        = "rgba(313244aa)",
            border_locked_active   = "rgba(f38ba8ee)",
            border_locked_inactive = "rgba(313244aa)",
        },
        groupbar = {                           -- the tab strip above a group (i3 "tabbed")
            enabled       = true,
            render_titles = true,
            font_family   = "Eternal UI",      -- DOOM Eternal font; the Bold weight is caps-only
            font_weight_active   = "bold",
            font_weight_inactive = "bold",
            font_size     = 14,
            height        = 24,
            gradients     = true,
            gradient_rounding = 6,
            indicator_height  = 0,
            text_color          = "rgba(1e1e2eff)",
            text_color_inactive = "rgba(cdd6f4ff)",
            col = {
                active          = "rgba(89b4faee)",
                inactive        = "rgba(45475aee)",
                locked_active   = "rgba(f38ba8ee)",
                locked_inactive = "rgba(45475aee)",
            },
        },
    },
    decoration = {
        rounding = 8,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = true, range = 12, render_power = 3, color = 0x99000000 },
        blur   = { enabled = true, size = 4, passes = 2, vibrancy = 0.17 },
    },

    animations = { enabled = true },

    dwindle = {
        preserve_split = true,   -- needed for togglesplit
    },

    input = {
        kb_layout    = "us,se",  -- index 0 = us, 1 = se (see the layout binds below)
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll       = true,
            tap_to_click         = true,
            disable_while_typing = true,
        },
    },

    cursor = {
        -- uncomment if the cursor is invisible or glitchy on NVIDIA:
        -- no_hardware_cursors = 1,
    },

    misc = {
        disable_hyprland_logo   = true,
        force_default_wallpaper = 0,
        font_family             = "Eternal UI",   -- dialogs and error overlay
        focus_on_activate       = true,
    },
})

-- default curves and animations (copied from the upstream example)
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1} } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1} } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

-- "smart gaps": no gaps/rounding when a workspace has a single tiled window
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
hl.window_rule({ name = "no-gaps-f1",   match = { float = false, workspace = "f[1]" },   border_size = 0, rounding = 0 })

-- three-finger swipe switches workspaces
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

------------------------------------------------------------------ launching
hl.bind(mod .. " + Return",    hl.dsp.exec_cmd(terminal))
hl.bind("CTRL + Return",       hl.dsp.exec_cmd(terminal))
hl.bind("ALT + SUPER + E",     hl.dsp.exec_cmd("emacs --init-directory ~/.config/emacs"))
hl.bind(mod .. " + D",         hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + CTRL + L",  hl.dsp.exec_cmd(lock))
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mod .. " + ALT + M",   hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + P",         hl.dsp.exec_cmd(single_monitor_sh))   -- single external monitor <-> site layout (see monitors)

-- keyboard layout (old setxkbmap se / us binds)
hl.bind("ALT + SUPER + S", hl.dsp.exec_cmd("hyprctl switchxkblayout all 1"))
hl.bind("ALT + SUPER + U", hl.dsp.exec_cmd("hyprctl switchxkblayout all 0"))

-- screenshots
hl.bind("Print",         hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("hyprshot -m output -o ~/Pictures"))

------------------------------------------------------------------ focus / move (i3 j k l ; layout)
local dirs = { J = "left", K = "down", L = "up", semicolon = "right",
               left = "left", down = "down", up = "up", right = "right" }
for key, dir in pairs(dirs) do
    hl.bind(mod .. " + " .. key,             hl.dsp.focus({ direction = dir }))
    hl.bind(mod .. " + SHIFT + " .. key,     hl.dsp.window.move({ direction = dir }))
end

------------------------------------------------------------------ layout
hl.bind(mod .. " + H", hl.dsp.layout("preselect r"))   -- i3 "split h": next window opens to the right
hl.bind(mod .. " + V", hl.dsp.layout("preselect d"))   -- i3 "split v": next window opens below
hl.bind(mod .. " + E", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
-- i3 "layout tabbed" for the workspace: every tiled window on the current workspace becomes a tab of one group.
-- Pressing it again on a grouped window dissolves the group (windows tile again).
local function tab_workspace()
    local w = hl.get_active_window()
    if not w or w.floating then return end
    if w.group then hl.dispatch(hl.dsp.group.toggle()); return end
    hl.dispatch(hl.dsp.group.toggle())
    w = hl.get_active_window()
    local g = w and w.group
    if not g then return end
    local ws = w.workspace and w.workspace.id
    for _, x in ipairs(hl.get_windows()) do
        if x.address ~= w.address and not x.floating and not x.group and x.workspace and x.workspace.id == ws then
            g:add(x)
        end
    end
end
hl.bind(mod .. " + W", tab_workspace)
hl.bind(mod .. " + Tab",         hl.dsp.group.next())
hl.bind(mod .. " + SHIFT + Tab", hl.dsp.group.prev())
hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float())
hl.bind(mod .. " + space",         hl.dsp.exec_cmd("hyprctl switchxkblayout all next")) -- toggle us/se
hl.bind(mod .. " + CTRL + space",  hl.dsp.window.cycle_next())

-- scratchpad (replaces the unused i3 "stacking" bind)
hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("scratch"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratch" }))

------------------------------------------------------------------ workspaces
for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- mouse drag / resize
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

------------------------------------------------------------------ session
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- resize submap ($mod+r, same keys as the i3 resize mode)
hl.bind(mod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    local step = 20
    local moves = { J = {-step, 0}, K = {0, step}, L = {0, -step}, semicolon = {step, 0},
                    left = {-step, 0}, down = {0, step}, up = {0, -step}, right = {step, 0} }
    for key, d in pairs(moves) do
        hl.bind(key, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
    end
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("escape", hl.dsp.submap("reset"))
end)

------------------------------------------------------------------ media keys
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
-- brightness follows the focused monitor: the laptop panel over /sys/class/backlight, externals over DDC/CI
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(brightness .. " set focused 5%+"),                 { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(brightness .. " set focused 5%-"),                 { locked = true, repeating = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

------------------------------------------------------------------ window rules
hl.window_rule({ name = "emacs-ws2",    match = { class = "^([Ee]macs)$" },                          workspace = "2" })
hl.window_rule({ name = "chrome-ws3",   match = { class = "^([Gg]oogle-chrome)" },                   workspace = "3" })
hl.window_rule({ name = "telegram-ws4", match = { class = "^(org\\.telegram\\.desktop|TelegramDesktop)$" }, workspace = "4" })
hl.window_rule({ name = "matlab-ws5",   match = { class = "^([Mm][Aa][Tt][Ll][Aa][Bb])" },           workspace = "5" })
-- home: workspace 1 lives on the Lenovo 1440p screen, workspace 2 on the HP, whenever those monitors are connected
hl.workspace_rule({ workspace = "1", monitor = "desc:Lenovo Group Limited G27q-20 U63330HD" })
hl.workspace_rule({ workspace = "2", monitor = "desc:HP Inc. HP E24u G5 CN43172GTD" })
-- Windows programs (Proton/Steam games: class steam_app_<id>; Wine: <name>.exe) always open on workspace 1 (the Lenovo)
hl.window_rule({ name = "windows-apps-ws1", match = { class = "^(steam_app_\\d+|.*\\.[Ee][Xx][Ee])$" }, workspace = "1" })
-- DOOM Eternal (782330) and DOOM: The Dark Ages (3017860) run as a borderless XWayland window; Hyprland would otherwise tile it (suppress-maximize below),
-- leaving the game rendering at 2560x1396. Force it fullscreen on open so it gets the whole 2560x1440 monitor.
hl.window_rule({ name = "doom-eternal-fullscreen", match = { class = "^(steam_app_(782330|3017860))$" }, fullscreen = true })

hl.window_rule({ name = "pavucontrol-float", match = { class = "^(org\\.pulseaudio\\.pavucontrol|pavucontrol)$" }, float = true, size = {900, 600}, center = true })

-- upstream recommended rules
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

------------------------------------------------------------------ autostart
hl.on("hyprland.start", function()
    -- tell systemd --user the graphical session is up: xdg-desktop-portal (screen sharing, file dialogs)
    -- depends on graphical-session.target and never starts otherwise
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE XDG_SESSION_TYPE GTK_IM_MODULE QT_IM_MODULE XMODIFIERS && "
             .. "dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE GTK_IM_MODULE QT_IM_MODULE XMODIFIERS && systemctl --user start hyprland-session.target && "
             -- waybar runs as a user service (config/systemd/user/waybar.service): memory-capped and tied to the session,
             -- so a bar from an earlier session cannot outlive it. Restart, not start: the target may still be active from
             -- the previous session (nothing stops it on exit), and a fresh start re-reads the imported WAYLAND_DISPLAY.
             .. "systemctl --user restart waybar.service")
    hl.exec_cmd(set_x11_primary)
    hl.exec_cmd("awww-daemon")          -- wallpaper daemon (backend used by waypaper)
    hl.exec_cmd("sleep 1 && waypaper --restore")  -- reapply the wallpaper picked in waypaper
    hl.exec_cmd("hypridle")
    hl.exec_cmd("mako")
    hl.exec_cmd("ibus-daemon -rxRd")   -- input method: -r replace a stale daemon, -x XIM for X11 apps, -R restart engines, -d daemonize
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd(terminal)
    hl.exec_cmd("claude-desktop")
    hl.exec_cmd("code-insiders")
end)
