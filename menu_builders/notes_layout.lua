local _ = require("gettext")
local Spin = require("widgets.generic_spin")
local keys = require("core.keys")
local config = require("core.config")


-------------------------------------------------------------------------
-- NOTES LAYOUT CONFIGURATION MENU
-------------------------------------------------------------------------

local function buildMenuNotesLayoutOptions()
    -- Check if syncing with highlights is enabled
    local function isSyncEnabled()
        return config.isTrue(keys.notes.sync_with_highlights)
    end

    -- Helper to create editable menu items
    local function createEditableItems()
        return {
            -- Text Alignment
            {
                text = _("Text Alignment: Left"),
                radio = true,
                checked_func = function()
                    return config.read(keys.notes.alignment) == "left"
                end,
                callback = function()
                    config.write(keys.notes.alignment, "left")
                end,
                enabled_func = function() return not isSyncEnabled() end,
            },
            {
                text = _("Text Alignment: Center"),
                radio = true,
                checked_func = function()
                    return config.read(keys.notes.alignment) == "center"
                end,
                callback = function()
                    config.write(keys.notes.alignment, "center")
                end,
                enabled_func = function() return not isSyncEnabled() end,
            },
            {
                separator = true,
                text = _("Text Alignment: Right"),
                radio = true,
                checked_func = function()
                    return config.read(keys.notes.alignment) == "right"
                end,
                callback = function()
                    config.write(keys.notes.alignment, "right")
                end,
                enabled_func = function() return not isSyncEnabled() end,
            },

            -- Justified toggle
            {
                text_func = function()
                    return _("Justified: ") .. (config.isTrue(keys.notes.justified) and _("On") or _("Off"))
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    config.write(
                        keys.notes.justified,
                        not config.isTrue(keys.notes.justified)
                    )
                    touchmenu_instance:updateItems()
                end,
                enabled_func = function() return not isSyncEnabled() end,
            },

            -- Line Height
            {
                text_func = function()
                    local lh_raw = config.read(keys.notes.line_height) or 100
                    return _("Line Height: ") .. string.format("%.2f", lh_raw / 100)
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    Spin.show{
                        title = _("Line spacing"),
                        value = config.read(keys.notes.line_height) or 100,
                        min = 0,
                        max = 160,
                        step = 5,
                        default = 50,
                        onApply = function(value)
                            config.write(keys.notes.line_height, value)
                            touchmenu_instance:updateItems()
                        end,
                    }
                end,
                enabled_func = function() return not isSyncEnabled() end,
            },

            -- Base Font Size
            {
                text_func = function()
                    return _("Base Font Size: ") .. (config.read(keys.notes.font_size_base) or 48)
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    Spin.show{
                        title = _("Base Font Size"),
                        value = config.read(keys.notes.font_size_base) or 48,
                        min = 24,
                        max = 72,
                        step = 2,
                        default = 48,
                        onApply = function(value)
                            config.write(keys.notes.font_size_base, value)
                            touchmenu_instance:updateItems()
                        end,
                    }
                end,
                enabled_func = function() return not isSyncEnabled() end,
            },

            -- Minimum Font Size
            {
                text_func = function()
                    return _("Minimum Font Size: ") .. (config.read(keys.notes.font_size_min) or 12)
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    Spin.show{
                        title = _("Minimum Font Size"),
                        value = config.read(keys.notes.font_size_min) or 12,
                        min = 8,
                        max = 24,
                        step = 1,
                        default = 12,
                        onApply = function(value)
                            config.write(keys.notes.font_size_min, value)
                            touchmenu_instance:updateItems()
                        end,
                    }
                end,
                enabled_func = function() return not isSyncEnabled() end,
            },

            -- Note Width
            {
                text_func = function()
                    return _("Note Width %: ") .. (config.read(keys.notes.width_percent) or 90)
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    Spin.show{
                        title = _("Note Width Percentage"),
                        value = config.read(keys.notes.width_percent) or 90,
                        min = 60,
                        max = 95,
                        step = 1,
                        default = 90,
                        onApply = function(value)
                            config.write(keys.notes.width_percent, value)
                            touchmenu_instance:updateItems()
                        end,
                    }
                end,
                enabled_func = function() return not isSyncEnabled() end,
            },
        }
    end

    return {
        text = _("Notes Layout"),
        sub_item_table = {
            -- 1️⃣ Sync Highlights Layout checkbox
            {
                text_func = function()
                    return _("Sync with Highlights: ") .. (isSyncEnabled() and _("On") or _("Off"))
                end,
                keep_menu_open = true,
                callback = function(touchmenu_instance)
                    config.write(keys.notes.sync_with_highlights, not isSyncEnabled())
                    touchmenu_instance:updateItems()
                end,
            },

            -- 2️⃣ Copy Highlights Layout
            {
                text = _("Copy layout from Highlights"),
                keep_menu_open = true,  -- keep menu open after copying
                callback = function(touchmenu_instance)
                    local keys = {"text_alignment", "justified", "line_height", "font_size_base", "font_size_min", "width_percent"}
                    for _, key in ipairs(keys) do
                        local hs_key = "hs_" .. key
                        local ns_key = "ns_" .. key
                        local value = config.read(hs_key)
                        if value ~= nil then
                            config.write(ns_key, value)
                        end
                    end
                    touchmenu_instance:updateItems()  -- refresh menu texts
                end,
                enabled_func = function()
                    return not isSyncEnabled()
                end,
                separator = true,
            },

            -- 3️⃣ All editable notes options
            table.unpack(createEditableItems()),
        },
    }
end

return { buildMenuNotesLayoutOptions = buildMenuNotesLayoutOptions }
