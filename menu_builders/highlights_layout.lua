local _ = require("gettext")

local Spin = require("widgets.generic_spin")
local config = require("core.config")
local keys = require("core.keys")
-------------------------------------------------------------------------
-- SCREENSAVER UI CONFIGURATION
-------------------------------------------------------------------------
local function buildMenuHighlightsLayoutOptions()
    return {
        text = _("Highlights Layout"),
        sub_item_table = {
            -- Text alignment
            {
                text = _("Text Alignment: Left"),
                radio = true,
                checked_func = function()
                    return config.read(keys.highlights.alignment) == "left"
                end,
                callback = function()
                    config.write(keys.highlights.alignment, "left")
                end,
            },
            {
                text = _("Text Alignment: Center"),
                radio = true,
                checked_func = function()
                    return config.read(keys.highlights.alignment) == "center"
                end,
                callback = function()
                    config.write(keys.highlights.alignment, "center")
                end,
            },
            {
                text = _("Text Alignment: Right"),
                radio = true,
                checked_func = function()
                    return config.read(keys.highlights.alignment) == "right"
                end,
                callback = function()
                    config.write(keys.highlights.alignment, "right")
                end,
                separator = true,
            },

            -- Justification toggle
            {
                text_func = function()
                    return _("Justified: ")
                        .. (config.isTrue(keys.highlights.justified) and _("On") or _("Off"))
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    config.write(
                        keys.highlights.justified,
                        not config.isTrue(keys.highlights.justified)
                    )

                    -- 🔥 THIS is the missing line
                    touchmenu_instance:updateItems()
                end,
            },

            -- Line height slider
            {
                text_func = function()
                    local lh_raw = config.read(keys.highlights.line_height) or 100
                    return _("Line Height: ") .. string.format("%.2f", lh_raw / 100)
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    
                    Spin.show{
                        title = _("Line spacing"),
                        value = config.read(keys.highlights.line_height) or 100,
                        min = 00,        -- 0.60
                        max = 160,       -- 1.60
                        step = 5,        -- 0.05
                        default = 50,   -- 1.00
                        onApply = function(value)
                            config.write(keys.highlights.line_height, value)
                            touchmenu_instance:updateItems()
                        end,
                    }
                end,
            },




            -- Quote width
            {
                text_func = function()
                    return _("Quote Width %: ") .. (config.read(keys.highlights.width_percent) or 90)
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    
                    Spin.show{
                        title = _("Quote Width Percentage"),
                        value = config.read(keys.highlights.width_percent) or 90,
                        min = 60,
                        max = 95,
                        step = 1,
                        default = 90,
                        onApply = function(value)
                            config.write(keys.highlights.width_percent, value)
                            touchmenu_instance:updateItems()
                        end,
                    }
                end,
            }

,

            -- Base font size
            {
                text_func = function()
                    return _("Base Font Size: ") .. (config.read(keys.highlights.font_size_base) or 48)
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    
                    Spin.show{
                        title = _("Base Font Size"),
                        value = config.read(keys.highlights.font_size_base) or 48,
                        min = 24,
                        max = 72,
                        step = 2,
                        default = 48,
                        onApply = function(value)
                            config.write(keys.highlights.font_size_base, value)
                            touchmenu_instance:updateItems()
                        end,
                    }
                end,
            }
,

            -- Min font size
            {
                text_func = function()
                    return _("Minimum Font Size: ") .. (config.read(keys.highlights.font_size_min) or 12)
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    
                    Spin.show{
                        title = _("Minimum Font Size"),
                        value = config.read(keys.highlights.font_size_min) or 12,
                        min = 8,
                        max = 24,
                        step = 1,
                        default = 12,
                        onApply = function(value)
                            config.write(keys.highlights.font_size_min, value)
                            touchmenu_instance:updateItems()
                        end,
                    }
                end,
            },

            -- Border Spacing 
            {
                text_func = function()
                    return _("Border Spacing: ")
                        .. (config.read(keys.highlights.border_spacing) or 24)
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    Spin.show{
                        title = _("Spacing between border and text"),
                        value = config.read(keys.highlights.border_spacing) or 24,
                        min = 0,
                        max = 40,
                        step = 2,
                        default = 24,
                        onApply = function(value)
                            config.write(keys.highlights.border_spacing, value)
                            touchmenu_instance:updateItems()
                        end,
                    }
                end,
            },

        }
    }
end

return {
    buildMenuHighlightsLayoutOptions = buildMenuHighlightsLayoutOptions
}
