--[[
    Utilities
    =========
    Filesystem path helpers and string normalization.
]]
local Device = require("device")
local lfs = require("libs/libkoreader-lfs")

local M = {}

--- Get the device-appropriate root directory for user data.
--- @return string
function M.getDefaultRootDir()
	if Device:isCervantes() or Device:isKobo() then
		return "/mnt"
	elseif Device:isEmulator() then
		return lfs.currentdir()
	else
		return Device.home_dir or lfs.currentdir()
	end
end

--- Get the plugin's data directory path.
--- @return string
function M.getPluginDir()
	return M.getDefaultRootDir() .. "/onboard/highlights-screensaver"
end

--- Get the clippings storage directory path.
--- @return string
function M.getClippingsDir()
	return M.getPluginDir() .. "/clippings"
end

--- Recursively create directories along a path.
--- @param path string  Absolute path to create
--- @return boolean|nil ok
--- @return string|nil  error message on failure
function M.makeDir(path)
	local current = ""
	for dir in path:gmatch("[^/]+") do
		current = current .. "/" .. dir
		local attr = lfs.attributes(current, "mode")
		if not attr then
			local ok, err = lfs.mkdir(current)
			if not ok then
				return nil, "Failed to create directory '" .. current .. "': " .. err
			end
		end
	end
	return true
end

--- Normalize a string for use as a safe filename.
--- Trims, lowercases, replaces spaces with underscores, removes unsafe chars.
--- @param s string
--- @return string
function M.normalise(s)
	s = s:match("^%s*(.-)%s*$") -- trim
	s = s:lower()
	s = s:gsub("%s+", "_") -- spaces → underscore
	s = s:gsub("[^%w_%-%.]", "") -- remove unsafe filename chars
	return s
end

return M
