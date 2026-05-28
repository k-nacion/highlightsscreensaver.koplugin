--[[
    Screensaver Display
    ===================
    Builds the full-screen highlight widget shown when the screensaver
    activates in "highlights" mode. Composes:
      - ui/theme_helpers    (color resolution)
      - ui/message_widget   (optional message overlay)
    
    Auto-shrinks font size until content fits within 95% of screen height.
]]
local CenterContainer = require("ui/widget/container/centercontainer")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local TextBoxWidget = require("ui/widget/textboxwidget")
local Device = require("device")
local Screen = Device.screen
local ScreenSaverWidget = require("ui/widget/screensaverwidget")
local Size = require("ui/size")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local LineWidget = require("ui/widget/linewidget")
local OverlapGroup = require("ui/widget/overlapgroup")
local BottomContainer = require("ui/widget/container/bottomcontainer")

local config = require("core.config")
local K = require("core.keys")
local themeHelpers = require("ui.theme_helpers")
local messageWidget = require("ui.message_widget")

local M = {}

----------------------------------------------------------------
-- Notes configuration
----------------------------------------------------------------

--- Build a config table for notes layout, respecting sync-with-highlights toggle.
--- @return table { text_alignment, line_height, width_percent, font_base, font_min }
local function getNoteConfig()
    if config.read(K.notes.sync_with_highlights) then
        return {
            text_alignment = config.read(K.highlights.alignment) or "left",
            line_height = (config.read(K.highlights.line_height) or 100) / 100,
            width_percent = config.read(K.highlights.width_percent) or 90,
            font_base = config.read(K.highlights.font_size_base) or 48,
            font_min = config.read(K.highlights.font_size_min) or 12,
        }
    else
        return {
            text_alignment = config.read(K.notes.alignment) or "left",
            line_height = (config.read(K.notes.line_height) or 100) / 100,
            width_percent = config.read(K.notes.width_percent) or 90,
            font_base = config.read(K.notes.font_base) or 48,
            font_min = config.read(K.notes.font_min) or 12,
        }
    end
end

----------------------------------------------------------------
-- Main entry
----------------------------------------------------------------

--- Build the full screensaver widget for a given highlight clipping.
--- @param ui table|nil      KOReader UI instance
--- @param clipping Clipping  The highlight data to display
--- @return table  ScreenSaverWidget ready for UIManager:show()
function M.buildHighlightsScreensaverWidget(ui, clipping)
    local col_fg, col_bg = themeHelpers.getThemeColors()
    local fonts = config.getFonts()

    local hs_cfg = getNoteConfig()
    local hs_width = Screen:getWidth() * (hs_cfg.width_percent / 100)

    local function buildContent(base_font_size)
        local function fontSizeAlt()
            return math.ceil(base_font_size * 0.75)
        end

        local highlight_text = TextBoxWidget:new {
            text = clipping.text,
            face = Font:getFace(fonts.quote, base_font_size),
            width = hs_width,
            alignment = hs_cfg.text_alignment,
            justified = config.read(K.highlights.justified),
            line_height = hs_cfg.line_height,
            fgcolor = col_fg,
            bgcolor = col_bg,
        }

        local highlight_group = HorizontalGroup:new {
            LineWidget:new {
                dimen = Geom:new {
                    w = Size.border.thick,
                    h = highlight_text:getSize().h,
                },
                background = col_fg,
            },
            HorizontalSpan:new { width = config.read(K.highlights.border_spacing) or 24 },
            highlight_text,
        }

        local author_suffix = clipping.source_author and (", " .. clipping.source_author) or ""

        local source_text = TextBoxWidget:new {
            text = "— " .. clipping.source_title .. author_suffix,
            face = Font:getFace(fonts.author, fontSizeAlt()),
            width = hs_width,
            fgcolor = col_fg,
            bgcolor = col_bg,
            alignment = "left",
        }

        local content = VerticalGroup:new {
            highlight_group,
            VerticalSpan:new { width = 24 },
            source_text,
        }

        -- Notes
        local notes_option = config.read(K.notes.option.mode) or "full"

        if clipping.note and clipping.note ~= "" and notes_option ~= "disable" then
            local note_text_value = clipping.note
            if notes_option == "short" then
                local max_chars = config.read(K.notes.option.limit) or 70
                if #note_text_value > max_chars then
                    note_text_value = note_text_value:sub(1, max_chars) .. "..."
                end
            end

            local note_width = Screen:getWidth() * (hs_cfg.width_percent / 100)
            local note_font_size = math.ceil(hs_cfg.font_base * 0.75)

            local note_text = TextBoxWidget:new {
                text = note_text_value,
                face = Font:getFace(fonts.note, note_font_size),
                width = note_width,
                fgcolor = col_fg,
                bgcolor = col_bg,
                alignment = hs_cfg.text_alignment,
                line_height = hs_cfg.line_height,
            }

            table.insert(content, VerticalSpan:new { width = 32 })
            table.insert(content,
                    LineWidget:new {
                        dimen = Geom:new { w = note_width, h = Size.line.thin },
                        background = col_fg,
                    }
            )
            table.insert(content, VerticalSpan:new { width = 24 })
            table.insert(content, note_text)
        end

        return content
    end

    -- Auto-shrink font until content fits screen
    local font_size = hs_cfg.font_base
    local content = buildContent(font_size)
    while content:getSize().h > Screen:getHeight() * 0.95 and font_size > hs_cfg.font_min do
        font_size = font_size - 2
        content = buildContent(font_size)
    end

    local msg_widget = messageWidget.build(ui, font_size, content:getSize().w, col_fg)

    local final_content
    if msg_widget and config.read(K.koreader.screensaver.container) == "banner" then
        final_content = OverlapGroup:new {
            CenterContainer:new {
                dimen = Screen:getSize(),
                content,
            },
            BottomContainer:new {
                dimen = Screen:getSize(),
                msg_widget,
            },
        }
    else
        final_content = VerticalGroup:new { content, msg_widget }
    end

    return ScreenSaverWidget:new {
        widget = CenterContainer:new {
            dimen = Screen:getSize(),
            final_content,
            padding = 0,
            margin = 0,
            bgcolor = col_bg,
        },
        background = col_bg,
        covers_fullscreen = true,
    }
end

return M
