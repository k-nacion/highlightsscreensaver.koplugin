--[[
    Screensaver Patch
    =================
    Monkey-patches Screensaver.show() to support the "highlights" screensaver type.
    Called from main.lua init() — never executes at require() time.
    Guarded against double-patching via the `patched` flag.
]]

local Screensaver = require("ui/screensaver")
local highlightsWidget = require("ui.screensaver_display")
local UIManager = require("ui/uimanager")
local Device = require("device")
local Screen = Device.screen

local config = require("core.config")
local clipper = require("core.clipper")
local scan = require("core.scan")
local keys = require("core.keys")
local Logger = require("core.logger")

local HIGHLIGHTS_MODE = "highlights"
local ORIENT_DEFAULT  = "default"
local ORIENT_PORTRAIT = "portrait"
local ORIENT_LANDSCAPE = "landscape"

local ROT_UPRIGHT  = Screen.DEVICE_ROTATED_UPRIGHT or 0
local ROT_LEFT     = Screen.DEVICE_ROTATED_LEFT or 1

local patched = false

local function patchScreensaverShow()
    if patched then return end
    patched = true

    local og_show = Screensaver.show

    Screensaver.show = function(self)
        if self.screensaver_type ~= HIGHLIGHTS_MODE then
            return og_show(self)
        end

        -- Wrap in pcall: if anything fails, fall back to default screensaver
        local ok, err = pcall(function()
            -- Close any existing screensaver widget
            if self.screensaver_widget then
                UIManager:close(self.screensaver_widget)
                self.screensaver_widget = nil
            end

            Device.screen_saver_mode = true

            -- Save current rotation
            local rotation_mode = Screen:getRotationMode()
            Device.orig_rotation_mode = rotation_mode

            -- Read our plugin-owned orientation
            local mode = config.read(keys.display.orientation) or ORIENT_DEFAULT

            -- Apply rotation only if needed
            if mode == ORIENT_PORTRAIT then
                if bit.band(rotation_mode, 1) == 1 then
                    Screen:setRotationMode(ROT_UPRIGHT)
                else
                    Device.orig_rotation_mode = nil
                end
            elseif mode == ORIENT_LANDSCAPE then
                if bit.band(rotation_mode, 1) == 0 then
                    Screen:setRotationMode(ROT_LEFT)
                else
                    Device.orig_rotation_mode = nil
                end
            else
                Device.orig_rotation_mode = nil
            end

            -- Highlight scanning logic
            local last_scanned = config.getLastScannedDate()
            local t = os.date("*t")
            local today = string.format("%04d-%02d-%02d", t.year, t.month, t.day)
            if not last_scanned or last_scanned < today then
                scan.scanHighlights()
            end

            local quote_order = config.read(keys.display.quote_order) or "random"
            local clipping
            if quote_order == "sequential" then
                clipping = clipper.getNextClipping()
            else
                clipping = clipper.getRandomClipping()
            end
            if clipping then
                config.setLastShownHighlight(clipping:filename())
            end

            -- Build and show widget
            self.screensaver_widget = highlightsWidget.buildHighlightsScreensaverWidget(self.ui, clipping)
            self.screensaver_widget.modal = true
            self.screensaver_widget.dithered = true
            UIManager:show(self.screensaver_widget, "full")
        end)

        if not ok then
            Logger.warn("[HighlightsScreensaver] Error showing highlights, falling back to default: " .. tostring(err))
            return og_show(self)
        end
    end
end

return {
    patchScreensaverShow = patchScreensaverShow,
}
