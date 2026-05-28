--[[
    Short Note Limit Spin Widget
    =============================
    Displays a SpinWidget that lets the user set the character limit
    for "short notes" displayed on the screensaver.
]]
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local M = {}

--- Show the short-note character-limit spin widget.
--- @param current_value number|nil  Current limit (defaults to 70)
--- @param onApply function|nil      Called with new value after confirmation
function M.show(current_value, onApply)
    local SpinWidget = require("ui/widget/spinwidget")

    UIManager:show(SpinWidget:new{
        title_text = _("Character limit for short notes"),
        value = current_value or 70,
        value_min = 10,
        value_max = 500,
        default_value = 70,

        callback = function(spin)
            G_reader_settings:saveSetting("show_notes_limit", spin.value)
            G_reader_settings:flush()

            if onApply then
                onApply(spin.value)
            end
        end,
    })
end

return M
