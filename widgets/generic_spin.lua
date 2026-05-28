--[[
    Generic Spin Widget
    ====================
    Displays a SpinWidget with configurable title, range, step, default,
    and callback. Single-purpose utility module.
]]
local UIManager = require("ui/uimanager")
local SpinWidget = require("ui/widget/spinwidget")

local M = {}

--- Show a generic spin widget.
--- @param opts table { title, value, min, max, step?, default, onApply? }
function M.show(opts)
    UIManager:show(SpinWidget:new{
        title_text = opts.title,
        value = opts.value,
        value_min = opts.min,
        value_max = opts.max,
        step = opts.step or 1,
        default_value = opts.default,
        callback = function(spin)
            if opts.onApply then
                opts.onApply(spin.value)
            end
        end,
    })
end

return M
