--[[
    Version Menu
    ============
    Displays the current plugin version and provides a manual
    "Check for update" option.
]]

local _ = require("gettext")
local updater = require("core.updater")

local M = {}

--- Build the "About & Updates" submenu
---@return table menu_item
function M.buildMenuVersion()
    return {
        text_func = function()
            return _("About (v") .. updater.getLocalVersion() .. ")"
        end,
        sub_item_table = {
            {
                text_func = function()
                    return _("Version: ") .. updater.getLocalVersion()
                end,
                keep_menu_open = true,
                callback = function() end, -- informational only
            },
            {
                text = _("Check for update"),
                keep_menu_open = true,
                callback = function()
                    updater.checkForUpdate()
                end,
            },
        },
    }
end

return M
