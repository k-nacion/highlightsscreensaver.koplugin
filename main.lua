--[[
    Highlights Screensaver Plugin for KOReader
    ==========================================
    Entry point. All initialization happens in init() to respect the
    KOReader plugin lifecycle. No side effects occur at require() time.

    Initialization order:
    1. Patch Screensaver.show to support "highlights" screensaver type
    2. Patch dofile to inject our menu into the screensaver settings menu
]]

local WidgetContainer = require("ui/widget/container/widgetcontainer")
local menu_injector = require("menu_builders._menu_injector")
local screensaver_patch = require("core.screensaver_patch")

local HighlightsScreensaver = WidgetContainer:extend({
    name = "Highlights Screensaver",
    is_doc_only = false,
})

function HighlightsScreensaver:init()
    -- Patch Screensaver.show (guarded against double-init)
    screensaver_patch.patchScreensaverShow()

    -- Patch dofile to inject our menu into KOReader's screensaver menu
    menu_injector.patchDofileMenus()
end

return HighlightsScreensaver
