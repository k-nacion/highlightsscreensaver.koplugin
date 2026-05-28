--[[
    Theme Helpers
    =============
    Resolves foreground/background colors based on the user's selected
    theme (System, Light, Dark) and KOReader's night-mode state.
]]
local Blitbuffer = require("ffi/blitbuffer")

local config = require("core.config")
local K = require("core.keys")

local M = {}

--- Resolve foreground and background colors for the current theme.
--- @return userdata fgcolor  (Blitbuffer color)
--- @return userdata bgcolor  (Blitbuffer color)
function M.getThemeColors()
    local theme = config.getTheme()
    local is_night_mode = G_reader_settings:isTrue(K.koreader.is_night_mode)

    if theme == config.Theme.SYSTEM then
        return Blitbuffer.COLOR_BLACK, Blitbuffer.COLOR_WHITE
    elseif (theme == config.Theme.DARK and not is_night_mode)
            or (theme == config.Theme.LIGHT and is_night_mode) then
        return Blitbuffer.COLOR_WHITE, Blitbuffer.COLOR_BLACK
    else
        return Blitbuffer.COLOR_BLACK, Blitbuffer.COLOR_WHITE
    end
end

return M
