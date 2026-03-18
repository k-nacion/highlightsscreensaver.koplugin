-- external_quotes.lua
local lfs = require("libs/libkoreader-lfs")
local Logger = require("core.logger")
local clipper = require("core.clipper")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local ffiUtil = require("ffi/util")  -- for SHA-1
local sha = require("dependency.sha2")

local M = {}

-- Generate a deterministic hash for a quote
local function generateQuoteHash(quote, author)
    local normalized = quote:gsub("^%s*(.-)%s*$", "%1")
    local key = normalized
    if author then
        key = key .. "~" .. author
    end
    local fullHash = sha.sha1(key)
    local shortHash = fullHash:sub(1, 12)
    return shortHash
end

-- trim helper (handles Windows/macOS/Linux weird filenames)
local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- split content by ====== delimiter
local function splitQuotes(content)
    local quotes = {}
    local buffer = {}

    for line in content:gmatch("[^\r\n]+") do
        if line:match("^=+$") then
            if #buffer > 0 then
                table.insert(quotes, table.concat(buffer, "\n"))
                buffer = {}
            end
        else
            table.insert(buffer, line)
        end
    end

    if #buffer > 0 then
        table.insert(quotes, table.concat(buffer, "\n"))
    end

    return quotes
end

-- extract author (expects "~ Author Name")
local function extractAuthor(text)
    local author = text:match("~%s*(.+)$")
    if author then
        text = text:gsub("\n~%s*.+$", "")
    end
    return trim(text), author
end

---@param dir_path string
function M.importQuotes(dir_path)
    Logger.info("[ExternalQuotes] Importing quotes from: " .. dir_path)

    local imported_count = 0
    local skipped_count = 0

    for file in lfs.dir(dir_path) do
        local clean_file = trim(file)

        if clean_file ~= "." and clean_file ~= ".."
                and clean_file:lower():match("%.txt$") then

            Logger.info("[ExternalQuotes] scanning file: '" .. clean_file .. "'")

            local filepath = dir_path .. "/" .. clean_file
            local f = io.open(filepath, "r")

            if f then
                local content = f:read("*a")
                f:close()

                if content and content:match("%S") then
                    local baseTitle = clean_file:gsub("%.txt$", "")
                    local quoteBlocks = splitQuotes(content)

                    local index = 1
                    for _, block in ipairs(quoteBlocks) do
                        local text, author = extractAuthor(block)
                        local hashId = generateQuoteHash(text, author)

                        if text and text:match("%S") then
                            -- Check if this quote already exists
                            if not clipper.hasClipping(hashId) then
                                local clipping = clipper.Clipping.new(
                                        text,
                                        nil,
                                        os.date("%Y-%m-%d %H:%M:%S"),
                                        baseTitle,
                                        author,
                                        true,
                                        hashId
                                )
                                clipping.source_index = index
                                index = index + 1

                                clipper.saveClipping(clipping)
                                imported_count = imported_count + 1

                                Logger.info(string.format(
                                        "[ExternalQuotes] Imported: %s (Author: %s)",
                                        text,
                                        author or "Unknown"
                                ))
                            else
                                skipped_count = skipped_count + 1
                                Logger.info(string.format(
                                        "[ExternalQuotes] Skipped duplicate: %s (Author: %s)",
                                        text,
                                        author or "Unknown"
                                ))
                            end
                        end
                    end
                end
            end
        end
    end

    UIManager:show(InfoMessage:new{
        text = string.format(
                "Imported %d quote(s), skipped %d duplicates from directory:\n%s",
                imported_count,
                skipped_count,
                dir_path
        ),
        timeout = 4,
    })
end

return M
