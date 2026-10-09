-- Hyprland look: window borders, group tabs, the font of the compositor's own text, extra layer rules.
-- Loaded by hyprland.lua (dofile); the values below are Catppuccin Mocha with the DOOM Eternal font.
-- The DOOM: The Dark Ages version is themes/dark-ages/config/hypr/theme.lua in the repo and
-- ./install.sh --theme dark-ages installs it over this file.
return {
    font     = "Eternal UI",     -- groupbar, dialogs and the error overlay; the Bold weight is caps-only
    rounding = 8,

    border_active   = "rgba(89b4faee)",   -- blue
    border_inactive = "rgba(313244aa)",
    border_locked   = "rgba(f38ba8ee)",   -- locked group: red

    group_active          = "rgba(89b4faee)",
    group_inactive        = "rgba(45475aee)",
    group_locked_active   = "rgba(f38ba8ee)",
    group_locked_inactive = "rgba(45475aee)",
    group_text            = "rgba(1e1e2eff)",
    group_text_inactive   = "rgba(cdd6f4ff)",
    group_font_weight     = "bold",
    group_rounding        = 6,

    layer_rules = {},             -- hl.layer_rule specs applied after the config (the Dark Ages theme blurs behind its bar)
}
