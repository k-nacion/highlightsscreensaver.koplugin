local _ = require("gettext")

local scanMenus = require("menu_builders.scan_menu")
local fontsMenus = require("menu_builders.fonts_menu")
local themeMenus = require("menu_builders.theme")
local highlightsMenus = require("menu_builders.highlights_layout")
local highlightsNotesMenu = require("menu_builders.highlight_notes_menu")
local importMenus = require("menu_builders.import_quotes_menu")
local orientationMenus = require("menu_builders.orientation_menu")
local disableHighlightMenus = require("menu_builders.disable_highlight_menu")
local toggleCollectionsMenus = require("menu_builders.toggle_collections_menu")
local quoteOrderMenus = require("menu_builders.quote_order_menu")
local notesLayoutMenus = require("menu_builders.notes_layout")
local screensaverMessageMenus = require("menu_builders.sleep_screen_message_menu")
local versionMenus = require("menu_builders.version_menu")

------------------------------------------------------------
-- 📖 Content
------------------------------------------------------------
local function buildMenuContent()
    return {
        text = _("Content"),
        sub_item_table = {
            scanMenus.buildMenuScanHighlights(),
            scanMenus.buildMenuAddScannableDirectory(),
            importMenus.buildMenuImportExternalQuotes(),
            disableHighlightMenus.buildMenuDisableHighlight(),
            toggleCollectionsMenus.buildMenuToggleCollections(),
        },
    }
end

------------------------------------------------------------
-- 🎨 Appearance
------------------------------------------------------------
local function buildMenuAppearance()
    return {
        text = _("Appearance"),
        sub_item_table = {
            themeMenus.buildMenuTheme(),
            fontsMenus.buildMenuFonts(),
        },
    }
end

------------------------------------------------------------
-- 📐 Layout
------------------------------------------------------------
local function buildMenuLayout()
    return {
        text = _("Layout"),
        sub_item_table = {
            highlightsMenus.buildMenuHighlightsLayoutOptions(),
            notesLayoutMenus.buildMenuNotesLayoutOptions(),
            highlightsNotesMenu.buildMenuShowHighlightNotes(),
        },
    }
end

------------------------------------------------------------
-- 🖥 Display
------------------------------------------------------------
local function buildMenuDisplay()
    return {
        text = _("Display"),
        sub_item_table = {
            orientationMenus.buildMenuToggleOrientation(),
            quoteOrderMenus.buildMenuQuoteOrder(),
            screensaverMessageMenus.buildMenuScreensaverMessageOptions(),
        },
    }
end

------------------------------------------------------------
-- TOP-LEVEL MENU
------------------------------------------------------------
local function buildHighlightsScreensaverMenu()
    return {
        text = _("Highlights screensaver"),
        sub_item_table = {
            buildMenuContent(),
            buildMenuAppearance(),
            buildMenuLayout(),
            buildMenuDisplay(),
            versionMenus.buildMenuVersion(),
        },
    }
end

return {
    buildHighlightsScreensaverMenu = buildHighlightsScreensaverMenu,
}
