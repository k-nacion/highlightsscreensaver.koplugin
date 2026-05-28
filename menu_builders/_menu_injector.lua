--[[
    Menu Injector
    =============
    Injects plugin menu items into KOReader's screensaver settings menu.
    
    KOReader loads screensaver_menu.lua via dofile(), and there is no official
    plugin hook to add items to that specific submenu. We intercept dofile()
    to inject our entries when that file is loaded.
    
    Called from main.lua init() — never executes at require() time.
    Guarded against double-patching via the `patched` flag.
]]

local _ = require("gettext")

local config = require("core.config")
local K = require("core.keys")

local highlightsMenu = require("menu_builders.highlights_screensaver_menu")


-- Constants
local HIGHLIGHTS_MODE = "highlights"

-------------------------------------------------------------------------
-- PATCH `dofile` TO INJECT MENUS
--
-- NOTE: KOReader loads the screensaver settings menu via dofile().
-- There is no official plugin hook to inject items into that specific
-- submenu, so we intercept dofile() to add our menu entries.
-- This is guarded against double-patching.
-------------------------------------------------------------------------

local patched = false
local orig_dofile = nil

local function patchDofileMenus()
    if patched then return end
    patched = true

    orig_dofile = dofile
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
