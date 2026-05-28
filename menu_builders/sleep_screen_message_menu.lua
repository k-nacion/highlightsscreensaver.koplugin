--
local _ = require("gettext")
local Screensaver = require("ui/screensaver")

local Spin = require("widgets.generic_spin")
local K = require("core.keys")
local config = require("core.config")

------------------------------------------------------------
-- Padding / Margin (ALL sides only)
------------------------------------------------------------
local function buildMenuPaddingMargin()
    return {
        text = _("Padding / Margin"),
        sub_item_table = {

            -- Padding (All)
            {
                text_func = function()
                    local v = config.read(K.screensaver_message.layout.padding) or 2
                    return _("Padding: ") .. v
                end,
                keep_menu_open = true,
                callback = function(touchmenu)
                    Spin.show {
                        title = _("Padding"),
                        value = config.read(K.screensaver_message.layout.padding) or 2,
                        min = 0,
                        max = 64,
                        step = 2,
                        default = 2,
                        onApply = function(v)
                            config.write(K.screensaver_message.layout.padding, v)
                            touchmenu:updateItems()
                        end,
                    }
                end,
            },

            -- Margin (All)
            {
                text_func = function()
                    local v = config.read(K.screensaver_message.layout.margin) or 24
                    return _("Margin: ") .. v
                end,
                keep_menu_open = true,
                callback = function(touchmenu)
                    Spin.show {
                        title = _("Margin"),
                        value = config.read(K.screensaver_message.layout.margin) or 4,
                        min = 0,
                        max = 64,
                        step = 2,
                        default = 4,
                        onApply = function(v)
                            config.write(K.screensaver_message.layout.margin, v)
                            touchmenu:updateItems()
                        end,
                    }
                end,
            },
        },
    }
end

------------------------------------------------------------
-- Alignment
------------------------------------------------------------
local function buildMenuAlignment()
    local function getAlignment()
        local align = config.read(K.screensaver_message.layout.alignment)
        if type(align) ~= "string" then
            align = "center" -- default
            config.write(K.screensaver_message.layout.alignment, align)
        end
        return align
    end

    return {
        text_func = function()
            local align = getAlignment()
            return _("Alignment: ") .. align:sub(1,1):upper() .. align:sub(2)
        end,
        sub_item_table = {
            {
                text = _("Left"),
                radio = true,
                checked_func = function()
                    return config.read(K.screensaver_message.layout.alignment) == "left"
                end,
                callback = function()
                    config.write(K.screensaver_message.layout.alignment, "left")
                end,
            },
            {
                text = _("Center"),
                radio = true,
                checked_func = function()
                    return config.read(K.screensaver_message.layout.alignment) == "center"
                end,
                callback = function()
                    config.write(K.screensaver_message.layout.alignment, "center")
                end,
            },
            {
                text = _("Right"),
                radio = true,
                checked_func = function()
                    return config.read(K.screensaver_message.layout.alignment) == "right"
                end,
                callback = function()
                    config.write(K.screensaver_message.layout.alignment, "right")
                end,
            },
        },
    }
end

------------------------------------------------------------
-- Line spacing
------------------------------------------------------------
local function buildMenuLineSpacing()
    return {
        text_func = function()
            local raw = config.read(K.screensaver_message.layout.line_spacing) or 0.4
            return _("Line Spacing: ") .. string.format("%.2f", raw)
        end,
        keep_menu_open = true,
        callback = function(touchmenu)
            local value = math.floor((config.read(K.screensaver_message.layout.line_spacing) or 0.4) * 100)
            Spin.show {
                title = _("Line Spacing"),
                value = value,
                min = 0,      -- 0.0
                max = 160,    -- 1.6
                step = 5,     -- 0.05
                onApply = function(v)
                    config.write(K.screensaver_message.layout.line_spacing, v / 100)
                    touchmenu:updateItems()
                end,
            }
        end,
    }
end


------------------------------------------------------------
-- Font size
------------------------------------------------------------
local function buildMenuFontSize()
    return {
        text_func = function()
            local value = config.read(K.screensaver_message.layout.font_size) or 48
            return _("Font Size: ") .. value
        end,
        keep_menu_open = true,
        callback = function(touchmenu)
            Spin.show {
                title = _("Font Size"),
                value = config.read(K.screensaver_message.layout.font_size) or 48,
                min = 4,
                max = 72,
                step = 2,
                default = 14,
                onApply = function(v)
                    config.write(K.screensaver_message.layout.font_size, v)
                    touchmenu:updateItems()
                end,
            }
        end,
    }
end

------------------------------------------------------------
-- Layout menu
------------------------------------------------------------
local function buildMenuSleepScreenMessageLayout()
    return {
        text = _("Layout"),
        sub_item_table = {
            buildMenuAlignment(),
            buildMenuLineSpacing(),
            buildMenuFontSize(),
            buildMenuPaddingMargin(),
        },
    }
end

------------------------------------------------------------
-- Main Sleep Screen Message menu
------------------------------------------------------------
local function buildMenuSleepScreenMessageOptions()

    local WIDTH_KEY = K.screensaver_message.width.mode

    local function getWidthMode()
        local mode = config.read(WIDTH_KEY)
        if type(mode) ~= "string" then
            mode = "message_content"      -- desired default
            config.write(WIDTH_KEY, mode)
        end
        return mode
    end


    return {
        separator = true,
        text = _("Sleep Screen Message"),
        sub_item_table = {

            {
                text = _("Edit sleep screen message"),
                keep_menu_open = true,
                callback = function()
                    Screensaver:setMessage()
                end,
            },

            {
                text_func = function()
                    local mode = config.read(K.koreader.screensaver.container) or "banner"
                    local label

                    if mode == "banner" then
                        label = _("Banner")
                    elseif mode == "box" then
                        label = _("Box")
                    else
                        label = _("Banner")
                    end

                    return _("Container: ") .. label
                end,
                sub_item_table = {
                    {
                        text = _("Banner"),
                        radio = true,
                        checked_func = function()
                            return (config.read(K.koreader.screensaver.container) or "banner") == "banner"
                        end,
                        callback = function()
                            config.write(K.koreader.screensaver.container, "banner")
                        end,
                    },
                    {
                        text = _("Box"),
                        radio = true,
                        checked_func = function()
                            return config.read(K.koreader.screensaver.container) == "box"
                        end,
                        callback = function()
                            config.write(K.koreader.screensaver.container, "box")
                        end,
                    },
                },
            },

            {
                text_func = function()
                    local mode = getWidthMode()
                    local label

                    if mode == "viewport" then
                        label = _("Viewport")
                    elseif mode == "message_content" then
                        label = _("Message Content")
                    elseif mode == "highlight" then
                        label = _("Highlight Width")
                    elseif mode == "custom" then
                        local v = config.read(K.screensaver_message.custom)
                        if type(v) == "number" then
                            label = _("Custom") .. " (" .. v .. ")"
                        else
                            label = _("Custom")
                        end
                    end

                    return _("Width: ") .. (label)
                end,
                sub_item_table = {
                    {
                        text = _("Viewport"),
                        radio = true,
                        checked_func = function()
                            return getWidthMode() == "viewport"
                        end,
                        callback = function()
                            config.write(K.screensaver_message.width.mode, "viewport")
                        end,
                    },
                    {
                        text = _("Message Content"),
                        radio = true,
                        checked_func = function()
                            return getWidthMode() == "message_content"
                        end,
                        callback = function()
                            config.write(K.screensaver_message.width.mode, "message_content")
                        end,
                    },
                    {
                        text = _("Highlight Width"),
                        radio = true,
                        checked_func = function()
                            return getWidthMode() == "highlight"
                        end,
                        callback = function()
                            config.write(K.screensaver_message.width.mode, "highlight")
                        end,
                    },
                    {
                        text_func = function()
                            local value = config.read(K.NAMESPACE .. "message_custom_width") or 50
                            return _("Custom Width: ") .. value
                        end,
                        radio = true,
                        checked_func = function()
                            return getWidthMode() == "custom"
                        end,
                        callback = function(touchmenu)
                            config.write(K.screensaver_message.width.mode, "custom")

                            local key = K.NAMESPACE .. "message_custom_width"
                            local value = config.read(key)

                            -- Ensure a persisted default exists
                            if type(value) ~= "number" then
                                value = 50
                                config.write(key, value)
                            end

                            Spin.show {
                                value = value,
                                min = 1,
                                max = math.huge, -- UI freedom
                                step = 10,
                                default = 50,
                                onApply = function(v)
                                    config.write(key, v)
                                    touchmenu:updateItems()
                                end,
                            }
                        end,

                    },
                },
            },

            buildMenuSleepScreenMessageLayout(),
        },
    }
end

return {
    buildMenuScreensaverMessageOptions = buildMenuSleepScreenMessageOptions,
}
