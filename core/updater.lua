--[[
    Updater Module
    ==============
    Handles manual "Check for update" functionality.
    
    Fetches the latest release version from GitHub, compares with the
    locally installed version, and if newer — downloads and installs
    the update (replacing the plugin directory contents).
    
    Only runs when the user explicitly taps "Check for update" in the menu.
    Never runs automatically to preserve battery on e-ink devices.
]]

local _ = require("gettext")
local InfoMessage = require("ui/widget/infomessage")
local ConfirmBox = require("ui/widget/confirmbox")
local UIManager = require("ui/uimanager")
local lfs = require("libs/libkoreader-lfs")

local Logger = require("core.logger")
local utils = require("core.utils")

local M = {}

------------------------------------------------------------
-- Configuration
------------------------------------------------------------
local GITHUB_REPO = "k-nacion/highlightsscreensaver.koplugin"
local API_URL = "https://api.github.com/repos/" .. GITHUB_REPO .. "/releases/latest"
local PLUGIN_DIR = utils.getPluginDir() .. "/../highlightsscreensaver.koplugin"

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

--- Get the local plugin directory (where files are installed)
local function getInstallDir()
    -- The plugin is loaded from its own directory; find it via package path
    local info = debug.getinfo(1, "S")
    local source = info.source
    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end
    -- source is something like /path/to/highlightsscreensaver.koplugin/core/updater.lua
    local dir = source:match("(.*/highlightsscreensaver%.koplugin)/")
    return dir or "."
end

--- Simple semver comparison: returns true if remote > local
--- Handles versions like "1.3.4-community", "v1.4.0", etc.
---@param local_ver string  e.g. "1.3.4-community"
---@param remote_ver string e.g. "v1.4.0" or "1.4.0-community"
---@return boolean
local function isNewerVersion(local_ver, remote_ver)
    -- Strip leading "v" and any suffix after the version numbers (e.g. "-community")
    local function parseVersion(v)
        v = v:gsub("^v", "")
        local major, minor, patch = v:match("^(%d+)%.(%d+)%.(%d+)")
        return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
    end

    local lmaj, lmin, lpat = parseVersion(local_ver)
    local rmaj, rmin, rpat = parseVersion(remote_ver)

    if rmaj ~= lmaj then return rmaj > lmaj end
    if rmin ~= lmin then return rmin > lmin end
    return rpat > lpat
end

--- Perform an HTTP GET request using KOReader's available HTTP facilities
---@param url string
---@return string|nil body
---@return string|nil error_message
local function httpGet(url)
    -- KOReader provides various HTTP options; try them in order of preference
    local ok, http = pcall(require, "socket.http")
    if not ok then
        -- Fallback: try https via ssl.https
        ok, http = pcall(require, "ssl.https")
    end

    if not ok or not http then
        return nil, "HTTP library not available"
    end

    local ltn12 = require("ltn12")
    local response_body = {}

    local _, status_code, headers = http.request({
        url = url,
        method = "GET",
        headers = {
            ["User-Agent"] = "KOReader-HighlightsScreensaver/1.0",
            ["Accept"] = "application/vnd.github.v3+json",
        },
        sink = ltn12.sink.table(response_body),
        redirect = true,
    })

    if status_code ~= 200 then
        return nil, "HTTP " .. tostring(status_code)
    end

    return table.concat(response_body)
end

--- Download a file from URL to a local path
---@param url string
---@param dest_path string
---@return boolean success
---@return string|nil error_message
local function downloadFile(url, dest_path)
    local ok, http = pcall(require, "socket.http")
    if not ok then
        ok, http = pcall(require, "ssl.https")
    end
    if not ok or not http then
        return false, "HTTP library not available"
    end

    local ltn12 = require("ltn12")
    local file, err = io.open(dest_path, "wb")
    if not file then
        return false, "Cannot open file: " .. tostring(err)
    end

    local _, status_code = http.request({
        url = url,
        method = "GET",
        headers = {
            ["User-Agent"] = "KOReader-HighlightsScreensaver/1.0",
        },
        sink = ltn12.sink.file(file),
        redirect = true,
    })

    if status_code ~= 200 then
        os.remove(dest_path)
        return false, "Download failed: HTTP " .. tostring(status_code)
    end

    return true
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

--- Get the currently installed version from _meta.lua
---@return string
function M.getLocalVersion()
    local meta = require("_meta")
    return meta.version or "0.0.0"
end

--- Check for updates (manual trigger only).
--- Shows an InfoMessage with the result.
function M.checkForUpdate()
    UIManager:show(InfoMessage:new{
        text = _("Checking for updates…"),
        timeout = 2,
    })

    -- Schedule the actual check so the UI can render the message first
    UIManager:scheduleIn(0.5, function()
        local body, err = httpGet(API_URL)
        if not body then
            UIManager:show(InfoMessage:new{
                text = _("Failed to check for updates.\n\n") .. tostring(err),
            })
            return
        end

        -- Parse the JSON response
        local json = require("json")
        local ok, release = pcall(json.decode, body)
        if not ok or not release or not release.tag_name then
            UIManager:show(InfoMessage:new{
                text = _("Failed to parse update information."),
            })
            return
        end

        local remote_version = release.tag_name
        local local_version = M.getLocalVersion()

        if isNewerVersion(local_version, remote_version) then
            -- Find the zipball URL
            local download_url = release.zipball_url
            if release.assets and #release.assets > 0 then
                -- Prefer the first .zip asset if available
                for _, asset in ipairs(release.assets) do
                    if asset.browser_download_url and asset.browser_download_url:match("%.zip$") then
                        download_url = asset.browser_download_url
                        break
                    end
                end
            end

            UIManager:show(ConfirmBox:new{
                text = _("A new version is available!\n\n") ..
                       _("Current: v") .. local_version .. "\n" ..
                       _("Latest: ") .. remote_version .. "\n\n" ..
                       _("Would you like to download and install the update?\n(KOReader will need to be restarted)"),
                ok_text = _("Update"),
                cancel_text = _("Later"),
                ok_callback = function()
                    M.performUpdate(download_url, remote_version)
                end,
            })
        else
            UIManager:show(InfoMessage:new{
                text = _("You're up to date!\n\nInstalled: v") .. local_version,
            })
        end
    end)
end

--- Download and install the update
---@param download_url string
---@param version string
function M.performUpdate(download_url, version)
    UIManager:show(InfoMessage:new{
        text = _("Downloading update…"),
        timeout = 2,
    })

    UIManager:scheduleIn(0.5, function()
        local tmp_dir = "/tmp"
        local zip_path = tmp_dir .. "/highlightsscreensaver_update.zip"
        local extract_dir = tmp_dir .. "/highlightsscreensaver_update"

        -- Download
        local success, err = downloadFile(download_url, zip_path)
        if not success then
            UIManager:show(InfoMessage:new{
                text = _("Download failed.\n\n") .. tostring(err),
            })
            return
        end

        -- Extract using system unzip
        os.execute("rm -rf " .. extract_dir)
        local unzip_result = os.execute("unzip -o " .. zip_path .. " -d " .. extract_dir)
        if unzip_result ~= 0 and unzip_result ~= true then
            UIManager:show(InfoMessage:new{
                text = _("Failed to extract update archive."),
            })
            os.remove(zip_path)
            return
        end

        -- Find the extracted directory (GitHub zipballs have a top-level folder)
        local extracted_folder = nil
        for entry in lfs.dir(extract_dir) do
            if entry ~= "." and entry ~= ".." then
                local path = extract_dir .. "/" .. entry
                local attr = lfs.attributes(path)
                if attr and attr.mode == "directory" then
                    extracted_folder = path
                    break
                end
            end
        end

        if not extracted_folder then
            UIManager:show(InfoMessage:new{
                text = _("Update extraction failed: no folder found."),
            })
            os.remove(zip_path)
            return
        end

        -- Install: copy extracted files over the plugin directory
        local install_dir = getInstallDir()
        local cp_result = os.execute("cp -rf " .. extracted_folder .. "/* " .. install_dir .. "/")
        if cp_result ~= 0 and cp_result ~= true then
            UIManager:show(InfoMessage:new{
                text = _("Failed to install update files."),
            })
        else
            Logger.info("[Updater] Successfully updated to " .. version)
            UIManager:show(InfoMessage:new{
                text = _("Update installed successfully!\n\n") ..
                       _("Version: ") .. version .. "\n\n" ..
                       _("Please restart KOReader to apply changes."),
            })
        end

        -- Cleanup
        os.remove(zip_path)
        os.execute("rm -rf " .. extract_dir)
    end)
end

return M
