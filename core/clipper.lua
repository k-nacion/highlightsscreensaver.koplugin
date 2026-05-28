local json = require("json")
local lfs = require("libs/libkoreader-lfs")
local utils = require("core.utils")

local M = {}

---@class Clipping
---@field text string
---@field note string|nil
---@field created_at string
---@field source_title string
---@field source_author string|nil
---@field enabled boolean
---@field hash_value string|nil  -- NEW
M.Clipping = {}
M.Clipping.__index = M.Clipping

---@param text string
---@param note string|nil
---@param created_at string
---@param source_title string
---@param source_author string|nil
---@param enabled boolean
---@return Clipping
function M.Clipping.new(text, note, created_at, source_title, source_author, enabled, hash_value)
	local self = setmetatable({}, M.Clipping)
	self.text = text
	self.note = note
	self.created_at = created_at
	self.source_title = source_title
	self.source_author = source_author
	self.enabled = enabled
	self.hash_value = hash_value  -- now works
	return self
end


---@param self Clipping
---@return string
function M.Clipping:filename()
	local index_part = self.source_index and ("_" .. self.source_index) or ""
	local created = self.created_at or "unknown_date"
	return utils.normalise(self.source_title .. " " .. created .. index_part .. ".json")
end



---@param path string
---@return Clipping[]
function M.extractClippingsFromSidecar(path)
  local metadata_path
	for file in lfs.dir(path) do
		if file:match("^metadata%..-%.lua$") then
			metadata_path = path .. "/" .. file
			break
		end
	end
	local metadata = dofile(metadata_path)

	-- Safely read metadata.stats if it exists
	local stats = metadata.stats or {}

	-- Fall back to top-level fields if needed
	local authors = stats.authors or metadata.authors or "Unknown Author"
	local title = stats.title or metadata.title or "Untitled"

	local clippings = {}

	-- Safely read metadata.annotations if it exists
	local annotation_list = metadata.annotations or {}
	for _, annotation in ipairs(annotation_list) do

		local clipping =
			M.Clipping.new(annotation.text, annotation.note or nil, annotation.datetime, title, authors, true)
		table.insert(clippings, clipping)
	end

	return clippings
end

---@param clipping Clipping
function M.saveClipping(clipping)
	utils.makeDir(utils.getClippingsDir())
	local path = utils.getClippingsDir() .. "/" .. clipping:filename()
	local file, err = io.open(path, "w")
	if not file then
		error("Error opening clippings file: " .. path .. ". Error: " .. tostring(err))
	end

	local content = json.encode(clipping, { indent = true })
	file:write(content)
	file:close()
end

---@param clipping Clipping
---@param filename string  The exact filename to write to (in clippings dir)
function M.saveClippingAs(clipping, filename)
	utils.makeDir(utils.getClippingsDir())
	local path = utils.getClippingsDir() .. "/" .. filename
	local file, err = io.open(path, "w")
	if not file then
		error("Error opening clippings file: " .. path .. ". Error: " .. tostring(err))
	end

	local content = json.encode(clipping, { indent = true })
	file:write(content)
	file:close()
end

---@param filename string
---@return Clipping|nil
function M.getClipping(filename)
	local path = utils.getClippingsDir() .. "/" .. filename
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	local data = json.decode(content)
	return M.Clipping.new(
			data.text,
			data.note,
			data.created_at,
			data.source_title,
			data.source_author,
			data.enabled,
			data.hash_value   -- restore the SHA here
	)
end

---@return Clipping
function M.getRandomClipping()
	local dir = utils.getClippingsDir()
	utils.makeDir(dir)

	math.randomseed(os.time())
	local chosenFile ---@type string|nil
	local count = 0

	-- reservoir sampling: https://en.wikipedia.org/wiki/Reservoir_sampling
	for file in lfs.dir(dir) do
		if file:match("%.json$") then
			local clipping = M.getClipping(file)
			if not clipping or not clipping.enabled then
				goto continue
			end

			count = count + 1
			if math.random(count) == 1 then
				chosenFile = file
			end
		end
		::continue::
	end

	local fallback_clipping = M.Clipping.new(
		"No highlights found. Ensure there there are valid scannable directories with books that contain highlights.",
		nil,
		"2025-11-12 00:19:09",
		"Highlights Screensaver",
		nil,
		true
	)
	if not chosenFile then
		return fallback_clipping
	end

	local clipping = M.getClipping(chosenFile)
	return clipping or fallback_clipping
end

---@return Clipping, string|nil  clipping and filename
function M.getNextClipping()
	local dir = utils.getClippingsDir()
	utils.makeDir(dir)

	-- Build sorted list of enabled clipping filenames
	local enabled_files = {}
	for file in lfs.dir(dir) do
		if file:match("%.json$") then
			local clipping = M.getClipping(file)
			if clipping and clipping.enabled then
				table.insert(enabled_files, file)
			end
		end
	end

	local fallback_clipping = M.Clipping.new(
		"No highlights found. Ensure there there are valid scannable directories with books that contain highlights.",
		nil,
		"2025-11-12 00:19:09",
		"Highlights Screensaver",
		nil,
		true
	)

	if #enabled_files == 0 then
		return fallback_clipping, nil
	end

	-- Sort for deterministic order
	table.sort(enabled_files)

	-- Get current index from config (lazy-require to avoid circular dep)
	local config = require("core.config")
	local current_index = config.getSequentialIndex()

	-- Advance to next position (wrapping around)
	current_index = current_index + 1
	if current_index > #enabled_files then
		current_index = 1
	end

	-- Save the new position
	config.setSequentialIndex(current_index)

	local chosen_file = enabled_files[current_index]
	local clipping = M.getClipping(chosen_file)
	return clipping or fallback_clipping, chosen_file
end

---@return table<string, {files: string[], enabled_count: number, total: number}>
function M.getCollections()
	local dir = utils.getClippingsDir()
	utils.makeDir(dir)
	local collections = {}

	for file in lfs.dir(dir) do
		if file:match("%.json$") then
			local clipping = M.getClipping(file)
			if clipping and clipping.source_title then
				local title = clipping.source_title
				if not collections[title] then
					collections[title] = { files = {}, enabled_count = 0, total = 0 }
				end
				table.insert(collections[title].files, file)
				collections[title].total = collections[title].total + 1
				if clipping.enabled then
					collections[title].enabled_count = collections[title].enabled_count + 1
				end
			end
		end
	end

	return collections
end

---@param source_title string
---@param enabled boolean
function M.setCollectionEnabled(source_title, enabled)
	local dir = utils.getClippingsDir()
	utils.makeDir(dir)

	for file in lfs.dir(dir) do
		if file:match("%.json$") then
			local clipping = M.getClipping(file)
			if clipping and clipping.source_title == source_title then
				clipping.enabled = enabled
				M.saveClippingAs(clipping, file)
			end
		end
	end
end

---@param hashId string
---@return boolean
function M.hasClipping(hashId)
	local dir = utils.getClippingsDir()
	utils.makeDir(dir)
	for file in lfs.dir(dir) do
		if file:match("%.json$") then
			local clipping = M.getClipping(file)
			if clipping and clipping.hash_value == hashId then
				return true
			end
		end
	end
	return false
end

return M