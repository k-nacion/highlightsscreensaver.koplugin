--[[
    Directory Picker Widget
    =======================
    Shows a path-chooser dialog and persists the selected directory.
    Used by the external quotes import menu.
]]
local UIManager = require("ui/uimanager")
local PathChooser = require("ui/widget/pathchooser")
local InfoMessage = require("ui/widget/infomessage")
local Logger = require("core.logger")
local lfs = require("libs/libkoreader-lfs")
local utils = require("core.utils")

local config = require("core.config")
local K = require("core.keys")


local M = {}


-- helper to trim whitespace/newlines
local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Get safe fallback directory
local function getFallbackDir()
    utils.getDefaultRootDir()
end

-- Get last path for a specific plugin, fallback to safe directory
local function getLastPath()
    local last_path = config.read(K.directory_picker.last_path)
    if last_path and last_path ~= "" then
        if lfs.attributes(last_path, "mode") == "directory" then
            return last_path
        end
    end
    return getFallbackDir()
end


-- Save last selected path for a specific plugin
local function saveLastPath(path)
    config.write(K.directory_picker.last_path, path)
end


-- Show PathChooser
-- plugin_name: string, used to remember last path per plugin
-- onConfirm: callback with the selected directory
function M.pickDirectory(onConfirm)
    local chooser = PathChooser:new{
        select_file = false,
        path = getLastPath(),
        onConfirm = function(dir_path)
            local clean_path = trim(dir_path)
            Logger.info("[DirectoryPicker] Selected: " .. clean_path)

            saveLastPath(clean_path)

            UIManager:show(InfoMessage:new{
                text = "Selected directory:\n" .. clean_path,
                timeout = 4,
            })

            if onConfirm then
                onConfirm(clean_path)
            end
        end,
    }

    UIManager:show(chooser)
end


return M
