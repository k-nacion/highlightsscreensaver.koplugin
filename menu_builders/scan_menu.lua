local _ = require("gettext")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local scan = require("core.scan")
local clipper = require("core.clipper")
local config = require("core.config")

local function buildMenuScanHighlights()
    return {
        text = _("Scan book highlights"),
        callback = function()
            scan.scanHighlights()
            UIManager:show(InfoMessage:new({ text = _("Finished scanning highlights") }))
        end,
    }
end

local function buildMenuAddScannableDirectory()
    return {
        text = _("Add current directory to scannable directories"),
        callback = function() scan.addToScannableDirectories() end,
    }
end

local function buildMenuDisableHighlight()
    return {
        text = _("Disable last shown highlight"),
        callback = function()
            local fname = config.getLastShownHighlight()
            if not fname then return end
            local clipping = clipper.getClipping(fname)
            if not clipping then return end
            clipping.enabled = false
            clipper.saveClipping(clipping)
            UIManager:show(InfoMessage:new({ text = _("Disabled highlight: " .. clipping:filename()) }))
        end,
        separator = true
    }
end

return {
    buildMenuScanHighlights = buildMenuScanHighlights,
    buildMenuAddScannableDirectory = buildMenuAddScannableDirectory,
    buildMenuDisableHighlight = buildMenuDisableHighlight,
}
