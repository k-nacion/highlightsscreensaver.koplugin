--[[
    Directory Scanner Widget
    ========================
    Scans a directory for .txt files and provides a summary popup.
    Used by the external quotes import feature.
]]
local lfs = require("libs/libkoreader-lfs")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local Logger = require("core.logger")

local DirectoryScanner = {}

-- helper to trim whitespace/newlines
local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Returns a list of .txt files (case-insensitive)
function DirectoryScanner.scanTextFiles(dir_path)
    Logger.info("[DirectoryScanner] Scanning directory: " .. dir_path)
    local txt_files = {}

    for file in lfs.dir(dir_path) do
        local clean_file = trim(file)  -- trim whitespace/newlines
        Logger.info("[DirectoryScanner] Found file: '" .. file .. "'")

        if clean_file ~= "." and clean_file ~= ".." and clean_file:lower():match("%.txt$") then
            table.insert(txt_files, dir_path .. "/" .. clean_file)
        end
    end

    Logger.info("[DirectoryScanner] Total text files found: " .. #txt_files)
    return txt_files
end

-- Shows a summary popup
function DirectoryScanner.showTextFileSummary(dir_path)
    local txt_files = DirectoryScanner.scanTextFiles(dir_path)
    local count = #txt_files
    local message = string.format(
        "Found %d text file(s) in:\n%s",
        count,
        dir_path
    )
    UIManager:show(InfoMessage:new({ text = message }))
end

return DirectoryScanner
