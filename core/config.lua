--[[
    Config Module
    =============
    Unified config system for the Highlights Screensaver plugin.

    Provides:
    - Default values and constants (Theme, Fonts)
    - Hybrid read/write routing (KOReader settings vs plugin settings)
    - JSON-based persistence for plugin-specific data (theme, dirs, fonts)

    Note: KOReader's plugin package path does not support init.lua in
    subdirectories, so this module is kept as a single file.
]]

local DataStorage = require("datastorage")
local LuaSettings = require("luasettings")
local json = require("json")

local K = require("core.keys")
local utils = require("core.utils")
local Logger = require("core.logger")

local M = {}

------------------------------------------------------------
-- SECTION: Defaults
------------------------------------------------------------

M.defaults = {
    ------------------------------------------------------------
    -- Plugin-owned screensaver message settings
    ------------------------------------------------------------
    [K.screensaver_message.width.mode]   = "message_content",
    [K.screensaver_message.width.custom_mode] = 50,

    [K.screensaver_message.layout.font_size]   = 14,
    [K.screensaver_message.layout.line_spacing] = 0.4,
    [K.screensaver_message.layout.alignment]    = "center",
    [K.screensaver_message.layout.padding]      = 2,
    [K.screensaver_message.layout.margin]       = 4,

    ------------------------------------------------------------
    -- Highlight Layout (READER SETTINGS)
    ------------------------------------------------------------
    [K.highlights.alignment]      = "left",
    [K.highlights.justified]      = false,
    [K.highlights.line_height]    = 0.3,
    [K.highlights.width_percent]  = 70,
    [K.highlights.font_size_base] = 32,
    [K.highlights.font_size_min]  = 12,
    [K.highlights.border_spacing] = 24,

    ------------------------------------------------------------
    -- Notes (READER SETTINGS)
    ------------------------------------------------------------
    [K.notes.sync_with_highlights] = true,

    [K.notes.alignment]      = "left",
    [K.notes.justified]      = false,
    [K.notes.line_height]    = 0.3,
    [K.notes.width_percent]  = 70,
    [K.notes.font_size_base] = 12,
    [K.notes.font_size_min]  = 24,

    [K.notes.option.mode] = "full",
    [K.notes.option.limit] = 130,

    ------------------------------------------------------------
    -- Screensaver type & display
    ------------------------------------------------------------
    [K.display.orientation] = "default",
    [K.display.quote_order] = "random",
}

------------------------------------------------------------
-- SECTION: Theme constants
------------------------------------------------------------
M.Theme = {
    SYSTEM = "system",
    DARK = "dark",
    LIGHT = "light",
}

------------------------------------------------------------
-- SECTION: Fonts class
------------------------------------------------------------

---@class Fonts
---@field quote string
---@field author string
---@field note string
local Fonts = {}
Fonts.__index = Fonts

M.Fonts = Fonts

M.DEFAULT_FONTS = {
    quote = "NotoSerif-BoldItalic.ttf",
    author = "NotoSerif-Regular.ttf",
    note = "NotoSerif-Bold.ttf",
}

------------------------------------------------------------
-- SECTION: Settings (hybrid read/write)
------------------------------------------------------------

local SETTINGS_FILE = DataStorage:getDataDir() .. "/highlightsscreensaver.lua"
local pluginSettings = LuaSettings:open(SETTINGS_FILE)

--- Determine if a key belongs to KOReader's settings
local function isKoreaderKey(key)
    for _, section in pairs(K.koreader) do
        if type(section) == "table" then
            for _, k in pairs(section) do
                if k == key then return true end
            end
        elseif section == key then
            return true
        end
    end
    return false
end

--- Hybrid read: routes to the appropriate settings backend
---@param key string
---@param default any
---@return any
function M.read(key, default)
    local fallback = default or M.defaults[key]

    if isKoreaderKey(key) then
        return G_reader_settings:readSetting(key, fallback)
    else
        return M.readPluginSetting(key, fallback)
    end
end

--- Hybrid write: routes to the appropriate settings backend
---@param key string
---@param value any
function M.write(key, value)
    if isKoreaderKey(key) then
        G_reader_settings:saveSetting(key, value)
    else
        M.writePluginSetting(key, value)
    end
end

--- Boolean convenience reader
---@param key string
---@return boolean
function M.isTrue(key)
    local val = M.read(key)
    if type(val) == "boolean" then
        return val
    elseif type(val) == "string" then
        return val:lower() == "true"
    elseif type(val) == "number" then
        return val ~= 0
    else
        return false
    end
end

--- Plugin-specific setting read
---@param key string
---@param default any
---@return any
function M.readPluginSetting(key, default)
    local value = pluginSettings:readSetting(key)
    if value == nil then
        return default
    end
    return value
end

--- Plugin-specific setting write
---@param key string
---@param value any
function M.writePluginSetting(key, value)
    pluginSettings:saveSetting(key, value)
    pluginSettings:flush()
end

--- Migration from legacy keys
function M.migrate()
    local rs = G_reader_settings

    local legacy = {
        screensaver_message_line_spacing = K.screensaver_message.layout.line_spacing,
        screensaver_message_font_size = K.screensaver_message.layout.font_size,
    }

    for old, new in pairs(legacy) do
        if rs:has(old) and not rs:has(new) then
            rs:saveSetting(new, rs:readSetting(old))
        end
    end
end

------------------------------------------------------------
-- SECTION: Persistence (JSON config)
------------------------------------------------------------

---@class Config
---@field theme string
---@field scannable_directories string[]
---@field last_scanned_date string|nil
---@field last_shown_highlight string|nil
---@field fonts Fonts
---@field external_quotes_directory string|nil
---@field sequential_index number
local Config = {}
Config.__index = Config

local function getConfigFilePath()
    return utils.getPluginDir() .. "/config.json"
end

local function deep_copy_no_mt(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = deep_copy_no_mt(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function loadConfig()
    local default_fonts = setmetatable({
        quote = M.DEFAULT_FONTS.quote,
        author = M.DEFAULT_FONTS.author,
        note = M.DEFAULT_FONTS.note,
    }, Fonts)

    local default_config = setmetatable({
        theme = M.Theme.SYSTEM,
        scannable_directories = {},
        last_scanned_date = nil,
        last_shown_highlight = nil,
        fonts = default_fonts,
        external_quotes_directory = nil,
        sequential_index = 0,
    }, Config)

    local file = io.open(getConfigFilePath(), "r")
    if not file then
        return default_config
    end

    local content = file:read("*a")
    file:close()

    local ok, data = pcall(json.decode, content)
    if not ok or not data then
        Logger.warn("[Config] Failed to parse config.json, using defaults")
        return default_config
    end

    return setmetatable({
        theme = data.theme or M.Theme.SYSTEM,
        scannable_directories = data.scannable_directories or {},
        last_scanned_date = data.last_scanned_date or nil,
        last_shown_highlight = data.last_shown_highlight or nil,
        fonts = data.fonts or default_fonts,
        external_quotes_directory = data.external_quotes_directory or nil,
        sequential_index = data.sequential_index or 0,
    }, Config)
end

function Config:save()
    local ok, err = pcall(function()
        local copy = deep_copy_no_mt(self)
        local content = json.encode(copy, { indent = true })
        utils.makeDir(utils.getPluginDir())
        local file, open_err = io.open(getConfigFilePath(), "w")
        if not file then
            error("Cannot open config.json for writing: " .. (open_err or "unknown"))
        end
        file:write(content)
        file:close()
    end)
    if not ok then
        Logger.warn("[Config] Failed to save config.json: " .. tostring(err))
    end
end

------------------------------------------------------------
-- Public getters/setters (persistence)
------------------------------------------------------------

---@return string
function M.getTheme()
    local config = loadConfig()
    return config.theme
end

---@param theme string
function M.setTheme(theme)
    local config = loadConfig()
    config.theme = theme
    config:save()
end

---@return string[]
function M.getScannableDirectories()
    local config = loadConfig()
    return config.scannable_directories
end

---@param dirs string[]
function M.setScannableDirectories(dirs)
    local config = loadConfig()
    config.scannable_directories = dirs
    config:save()
end

---@return string|nil
function M.getLastScannedDate()
    local config = loadConfig()
    return config.last_scanned_date
end

---@param date string
function M.setLastScannedDate(date)
    local config = loadConfig()
    config.last_scanned_date = date
    config:save()
end

---@return string|nil
function M.getLastShownHighlight()
    local config = loadConfig()
    return config.last_shown_highlight
end

---@param filename string
function M.setLastShownHighlight(filename)
    local config = loadConfig()
    config.last_shown_highlight = filename
    config:save()
end

---@return string|nil
function M.getExternalQuotesDirectory()
    local config = loadConfig()
    return config.external_quotes_directory
end

---@param dir string
function M.setExternalQuotesDirectory(dir)
    local config = loadConfig()
    config.external_quotes_directory = dir
    config:save()
end

---@param fonts Fonts
function M.setFonts(fonts)
    local config = loadConfig()
    config.fonts = fonts
    config:save()
end

---@return Fonts
function M.getFonts()
    local config = loadConfig()
    return config.fonts
end

---@return number
function M.getSequentialIndex()
    local config = loadConfig()
    return config.sequential_index
end

---@param index number
function M.setSequentialIndex(index)
    local config = loadConfig()
    config.sequential_index = index
    config:save()
end

return M
