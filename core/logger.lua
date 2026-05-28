--[[
    Logger
    ======
    Thin logging wrapper that prefixes messages with timestamp and level.
    Output goes to stdout (KOReader's log stream).
]]

---@class Logger
local M = {}

local LOG_PREFIX = "[HighlightSS Plugin]"

local function timestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

local function log(level, msg)
    local line = string.format(
        "%s %s [%s] %s",
        timestamp(),
        LOG_PREFIX,
        level,
        tostring(msg)
    )
    print(line)
end

--- Log an informational message.
--- @param msg string
function M.info(msg)
    log("INFO", msg)
end

--- Log a warning message.
--- @param msg string
function M.warn(msg)
    log("WARN", msg)
end

--- Log an error message.
--- @param msg string
function M.error(msg)
    log("ERROR", msg)
end

return M
