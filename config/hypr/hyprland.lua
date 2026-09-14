-- Hyprland config (Lua, Hyprland >= 0.56) — ported from the old ~/.i3/config
-- Docs: https://wiki.hypr.land/configuring/core/   Stubs for editor completion: /usr/share/hypr/stubs

local mod      = "SUPER"
local terminal = "tabby"
local menu     = "fuzzel"
local lock     = "pidof hyprlock || hyprlock"

------------------------------------------------------------------ monitors
-- Home layout, left to right, bottom-aligned. Externals are matched by make/model/serial ("desc:" from hyprctl monitors),
-- so other monitors on the same ports fall through to the "auto" rule at the end.
-- externals are matched by description (hyprctl monitors), so both sites can be listed; only the present ones apply
-- home: laptop panel left (bottom-aligned), Lenovo, HP
hl.monitor({ output = "desc:Lenovo Group Limited G27q-20 U63330HD", mode = "preferred", position = "2048x0",   scale = 1 })  -- Lenovo 2560x1440
hl.monitor({ output = "desc:HP Inc. HP E24u G5 CN43172GTD",        mode = "preferred", position = "4608x360", scale = 1 })  -- HP 1920x1080
-- office: Dell, AOC, Dell (bottom-aligned), laptop panel off
hl.monitor({ output = "desc:Dell Inc. DELL U2422H 3119RP3",         mode = "preferred", position = "0x360",    scale = 1 })  -- Dell 1920x1080 (left)
hl.monitor({ output = "desc:AOC Q27G42XE 1O0R4HA008572",            mode = "preferred", position = "1920x0",   scale = 1 })  -- AOC 2560x1440
hl.monitor({ output = "desc:Dell Inc. DELL U2422H 85LJRP3",         mode = "preferred", position = "4480x360", scale = 1 })  -- Dell 1920x1080 (right)

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
-- rules applied at config load work reliably; rules pushed later at runtime do not always re-enable a disabled
-- output, so on a dock/undock we simply reload the config and let this block run again.
local laptop_panel_docked = docked()
if laptop_panel_docked then
    hl.monitor({ output = "eDP-1", disabled = true })
else
    hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x160", scale = 1.25 }) -- 2560x1600 -> 2048x1280 logical
end
local function on_monitor_change()
    if docked() ~= laptop_panel_docked then hl.exec_cmd("hyprctl reload") end
end
hl.on("monitor.added",   on_monitor_change)
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
hl.bind("ALT + SUPER + E",     hl.dsp.exec_cmd("emacs --init-directory ~/.config/emacs"))
hl.bind(mod .. " + D",         hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + CTRL + L",  hl.dsp.exec_cmd(lock))
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.close())

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
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

------------------------------------------------------------------ window rules
hl.window_rule({ name = "emacs-ws2",    match = { class = "^([Ee]macs)$" },                          workspace = "2" })
hl.window_rule({ name = "chrome-ws3",   match = { class = "^([Gg]oogle-chrome)" },                   workspace = "3" })
hl.window_rule({ name = "telegram-ws4", match = { class = "^(org\\.telegram\\.desktop|TelegramDesktop)$" }, workspace = "4" })
hl.window_rule({ name = "matlab-ws5",   match = { class = "^([Mm][Aa][Tt][Ll][Aa][Bb])" },           workspace = "5" })
-- Windows programs (Proton/Steam games: class steam_app_<id>; Wine: <name>.exe) always open on workspace 2,
-- and workspace 2 is pinned to the Lenovo 1440p screen whenever that monitor is connected
hl.workspace_rule({ workspace = "2", monitor = "desc:Lenovo Group Limited G27q-20 U63330HD" })
hl.window_rule({ name = "windows-apps-ws2", match = { class = "^(steam_app_\\d+|.*\\.[Ee][Xx][Ee])$" }, workspace = "2" })

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
    hl.exec_cmd("waybar -c ~/.config/waybar/config-hyprland.jsonc")
    hl.exec_cmd("awww-daemon")          -- wallpaper daemon (backend used by waypaper)
    hl.exec_cmd("sleep 1 && waypaper --restore")  -- reapply the wallpaper picked in waypaper
    hl.exec_cmd("hypridle")
    hl.exec_cmd("mako")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd(terminal)
    hl.exec_cmd("claude-desktop")
    hl.exec_cmd("code-insiders")
end)
