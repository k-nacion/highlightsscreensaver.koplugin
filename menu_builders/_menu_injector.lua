-- lua
local _ = require("gettext")

local config = require("core.config")
local K = require("core.keys")

local highlightsMenu = require("menu_builders.highlights_screensaver_menu")


-- Constants
local HIGHLIGHTS_MODE = "highlights"

-------------------------------------------------------------------------
-- PATCH `dofile` TO INJECT MENUS
-------------------------------------------------------------------------

local function patchDofileMenus()
    local orig_dofile = dofile
    _G.dofile = function(filepath)
        local result = orig_dofile(filepath)

        if filepath and filepath:match("screensaver_menu%.lua$") then
            if result and result[1] and result[1].sub_item_table then
                local wallpaper_submenu = result[1].sub_item_table

                -- Add highlights screensaver menu
                table.insert(result, 3, highlightsMenu.buildHighlightsScreensaverMenu())


                -- Add option to select highlights screensaver
                table.insert(wallpaper_submenu, 6, {
                    text = _("Show highlights screensaver"),
                    radio = true,
                    checked_func = function()
                        return config.read(K.koreader.screensaver_type) == HIGHLIGHTS_MODE
                    end,
                    callback = function()
                        config.write(K.koreader.screensaver_type, HIGHLIGHTS_MODE)
                    end,
                })
            end
        end

        return result
    end
end

-------------------------------------------------------------------------
-- EXPORT
-------------------------------------------------------------------------

return {
    patchDofileMenus = patchDofileMenus,
}
