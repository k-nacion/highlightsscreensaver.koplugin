local json = require("json")
local utils = require("core.utils")
local K = require("core.keys")

local M = {}

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
}


-- Hybrid read
function M.read(key, default)
    local is_koreader_key = false
    for _, section in pairs(K.koreader) do
        if type(section) == "table" then
            for _, k in pairs(section) do
                if k == key then is_koreader_key = true break end
            end
        elseif section == key then
            is_koreader_key = true  -- <-- add this
        end
        if is_koreader_key then break end
    end

    if is_koreader_key then
        return G_reader_settings:readSetting(key, default or M.defaults[key])
    else
        return M.readPluginSetting(key, default or M.defaults[key])
    end
end

-- Hybrid write
function M.write(key, value)
    local is_koreader_key = false
    for _, section in pairs(K.koreader) do
        if type(section) == "table" then
            for _, k in pairs(section) do
                if k == key then is_koreader_key = true break end
            end
        elseif section == key then
            is_koreader_key = true
        end
        if is_koreader_key then break end
    end


    if is_koreader_key then
        G_reader_settings:saveSetting(key, value)
    else
        M.writePluginSetting(key, value)
    end
end

function M.isTrue(key)
    local val = M.read(key)  -- <-- uses your hybrid read
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

-- ===== NEW: Plugin-specific settings =====
local DataStorage = require("datastorage")
local LuaSettings = require("luasettings")

-- Plugin-owned LuaSettings (KOReader-native)
local SETTINGS_FILE = DataStorage:getDataDir() .. "/highlightsscreensaver.lua"

local pluginSettings = LuaSettings:open(SETTINGS_FILE)

-- Read a plugin-specific setting
function M.readPluginSetting(key, default)
    local value = pluginSettings:readSetting(key)
    if value == nil then
        return default
    end
    return value
end

-- Write a plugin-specific setting
function M.writePluginSetting(key, value)
    pluginSettings:saveSetting(key, value)
    pluginSettings:flush()
end

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

M.Theme = {
    SYSTEM = "system", -- new system theme
    DARK = "dark",
    LIGHT = "light",
}

---@class Fonts
---@field quote string
---@field author string
---@field note string
local Fonts = {}
Fonts.__index = Fonts

---@class Config
---@field theme Theme
---@field scannable_directories string[]
---@field last_scanned_date string|nil
---@field last_shown_highlight string|nil
---@field fonts Fonts
local Config = {}
Config.__index = Config

local function getConfigFilePath()
    return utils.getPluginDir() .. "/config.json"
end

local function load()
    local default_fonts = setmetatable({
        quote = "NotoSerif-BoldItalic.ttf",
        author = "NotoSerif-Regular.ttf",
        note = "NotoSerif-Bold.ttf",
    }, Fonts)

    local default_config = setmetatable({
        theme = M.Theme.SYSTEM, -- default theme is system
        scannable_directories = {},
        last_scanned_date = nil,
        last_shown_highlight = nil,
        fonts = default_fonts,
        external_quotes_directory = nil,
    }, Config)

    local file = io.open(getConfigFilePath(), "r")
    if not file then
        return default_config
    end

    local content = file:read("*a")
    file:close()
    local data = json.decode(content)
    if not data then
        return default_config
    end

    return setmetatable({
        theme = data.theme or M.Theme.SYSTEM, -- default to system
        scannable_directories = data.scannable_directories or {},
        last_scanned_date = data.last_scanned_date or nil,
        last_shown_highlight = data.last_shown_highlight or nil,
        fonts = data.fonts or default_fonts,
        external_quotes_directory = data.external_quotes_directory or nil,
    }, Config)
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

function Config:save()
    local copy = deep_copy_no_mt(self)
    local content = json.encode(copy, { indent = true })
    utils.makeDir(utils.getPluginDir())
    local file = assert(io.open(getConfigFilePath(), "w"))
    file:write(content)
    file:close()
end

---@return Theme
function M.getTheme()
    local config = load()
    return config.theme
end

---@param theme Theme
function M.setTheme(theme)
    local config = load()
    config.theme = theme
    config:save()
end

---@return string[]
function M.getScannableDirectories()
    local config = load()
    return config.scannable_directories
end

---@param dirs string[]
function M.setScannableDirectories(dirs)
    local config = load()
    config.scannable_directories = dirs
    config:save()
end

---@return string|nil
function M.getLastScannedDate()
    local config = load()
    return config.last_scanned_date
end

---@param date string
function M.setLastScannedDate(date)
    local config = load()
    config.last_scanned_date = date
    config:save()
end

---@return string|nil
function M.getLastShownHighlight()
    local config = load()
    return config.last_shown_highlight
end

---@param filename string
function M.setLastShownHighlight(filename)
    local config = load()
    config.last_shown_highlight = filename
    config:save()
end

---@return string|nil
function M.getExternalQuotesDirectory()
    local config = load()
    return config.external_quotes_directory
end

---@param dir string
function M.setExternalQuotesDirectory(dir)
    local config = load()
    config.external_quotes_directory = dir
    config:save()
end

---@param fonts Fonts
function M.setFonts(fonts)
    local config = load()
    config.fonts = fonts
    config:save()
end

---@return Fonts
function M.getFonts()
    local config = load()
    return config.fonts
end

M.Fonts = Fonts

return M
