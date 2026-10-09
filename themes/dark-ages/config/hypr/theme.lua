-- Hyprland look, DOOM: The Dark Ages (loaded by hyprland.lua). Teal glow on the focused window, hairline
-- borders elsewhere, orange for a locked group, square corners like the game's menus, the Cormorant serif.
-- Palette: themes/dark-ages/README.md.
return {
    font     = "Cormorant",
    rounding = 0,

    border_active   = "rgba(7fb3aeee)",   -- lit-row teal
    border_inactive = "rgba(2a4347aa)",   -- hairline
    border_locked   = "rgba(d0602aee)",   -- the orange bar

    group_active          = "rgba(7fb3aeee)",
    group_inactive        = "rgba(0f3033ee)",
    group_locked_active   = "rgba(d0602aee)",
    group_locked_inactive = "rgba(4a2a20ee)",
    group_text            = "rgba(061a1cff)",
    group_text_inactive   = "rgba(a4bebfff)",
    group_font_weight     = "bold",
    group_rounding        = 0,

    layer_rules = {
        -- the bar's stone texture is translucent: blur the wallpaper behind it (ignore_alpha keeps the bar's
        -- fully transparent parts, if any, unblurred)
        { name = "waybar-blur", match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.2 },
    },
}
