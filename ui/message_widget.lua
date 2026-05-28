--[[
    Message Widget Builder
    ======================
    Builds the optional "screensaver message" overlay (box or banner style)
    shown at the bottom or inline with the highlight content.
]]
local Blitbuffer = require("ffi/blitbuffer")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local TextBoxWidget = require("ui/widget/textboxwidget")
local Device = require("device")
local Screen = Device.screen
local Size = require("ui/size")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local LineWidget = require("ui/widget/linewidget")
local FrameContainer = require("ui/widget/container/framecontainer")

local config = require("core.config")
local K = require("core.keys")

local M = {}

----------------------------------------------------------------
-- Defensive helpers
----------------------------------------------------------------

--- @param key string
--- @param default number
--- @return number
local function readNumber(key, default)
    local v = config.read(key, default)
    if type(v) ~= "number" then
        return default
    end
    return v
end

----------------------------------------------------------------
-- Style helpers
----------------------------------------------------------------

--- Apply font-size, line-height, and alignment from config to a TextBoxWidget.
--- @param textw table  TextBoxWidget instance
--- @return table  The same widget, mutated
local function styleTextWidget(textw)
    local font_size = config.read(K.screensaver_message.layout.font_size)
    local line_height = config.read(K.screensaver_message.layout.line_spacing)
    local alignment = config.read(K.screensaver_message.layout.alignment) or "center"

    textw.line_height = line_height
    textw.alignment = alignment

    if textw.face and textw.face.family then
        textw.face = Font:getFace(textw.face.family, font_size)
    end

    return textw
end

----------------------------------------------------------------
-- Container builders
----------------------------------------------------------------

--- Build a boxed (framed) message container.
--- @param textw table  TextBoxWidget
--- @return table  FrameContainer widget
local function buildBoxMessage(textw)
    local textbw = styleTextWidget(textw)
    return FrameContainer:new {
        background = Blitbuffer.COLOR_WHITE,
        bordersize = Size.border.default,
        padding = readNumber(K.screensaver_message.layout.padding, Size.padding.large),
        margin = readNumber(K.screensaver_message.layout.margin, Size.margin.default),
        textbw,
    }
end

--- Build a banner-style message container (line + text, full-width options).
--- @param textw table  TextBoxWidget
--- @param highlight_width number|nil  Width of the highlight content
--- @param fgcolor userdata  Foreground Blitbuffer color
--- @return table  FrameContainer widget
local function buildBannerMessage(textw, highlight_width, fgcolor)
    local textbw = styleTextWidget(textw)

    local width_mode = config.read(K.screensaver_message.width.mode)
    local custom_width = config.read(K.screensaver_message.width.custom_mode)

    local banner_width
    if width_mode == "viewport" then
        banner_width = Screen:getWidth()
    elseif width_mode == "message_content" then
        banner_width = textbw:getSize().w
    elseif width_mode == "custom" then
        if type(custom_width) ~= "number" or custom_width == math.huge or custom_width ~= custom_width then
            banner_width = Screen:getWidth()
        else
            banner_width = custom_width
        end
    else
        banner_width = highlight_width or Screen:getWidth() * 0.9
    end

    local padding = readNumber(K.screensaver_message.layout.padding, Size.padding.large)
    local margin = readNumber(K.screensaver_message.layout.margin, Size.margin.default)

    local banner_content = VerticalGroup:new {
        LineWidget:new {
            dimen = Geom:new { w = banner_width, h = Size.border.default },
            background = fgcolor,
        },
        VerticalSpan:new { width = padding },
        textbw,
        VerticalSpan:new { width = padding },
    }

    return FrameContainer:new {
        background = Blitbuffer.COLOR_WHITE,
        bordersize = 0,
        padding = 0,
        margin = margin,
        dimen = { w = banner_width },
        banner_content,
    }
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

--- Build the optional screensaver message widget.
--- Returns nil if message display is disabled or message is empty.
--- @param ui table|nil        KOReader UI instance (for bookinfo expansion)
--- @param base_font_size number  Current font size used for highlights
--- @param content_width number   Width of the highlight content area
--- @param fgcolor userdata       Foreground Blitbuffer color
--- @return table|nil  Widget or nil
function M.build(ui, base_font_size, content_width, fgcolor)
    if not config.read(K.koreader.screensaver.show_message) then
        return nil
    end

    local message = config.read(K.koreader.screensaver.message)
    if not message or message == "" then
        return nil
    end

    if ui and ui.bookinfo then
        message = ui.bookinfo:expandString(message) or message
    end

    local textw = TextBoxWidget:new {
        text = message,
        face = Font:getFace("infofont", config.read(K.screensaver_message.layout.font_size)),
        alignment = config.read(K.screensaver_message.layout.alignment) or "center",
        line_height = config.read(K.screensaver_message.layout.line_spacing),
    }

    local container_type = config.read(K.koreader.screensaver.container) or "box"

    if container_type == "banner" then
        return buildBannerMessage(textw, content_width, fgcolor)
    end

    return buildBoxMessage(textw)
end

return M
