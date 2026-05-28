local _ = require("gettext")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local ffiUtil = require("ffi/util")
local T = ffiUtil.template
local config = require("core.config") -- Use our hybrid config
local K = require("core.keys")

-- Ensure default values exist
if not config.read(K.notes.option.mode) then
	config.write(K.notes.option.mode, "full")
end

if not config.read(K.notes.option.limit) then
	config.write(K.notes.option.limit, 70)
end

-- Helper: capitalize first letter
local function capitalizeFirstLetter(str)
	return str:gsub("^%l", string.upper)
end

-------------------------------------------------------------------------
-- SHOW HIGHLIGHT NOTES MENU
-------------------------------------------------------------------------
local function buildMenuShowHighlightNotes()
	return {
		text_func = function()
			local current_state = config.read(K.notes.option.mode) or "full"
			return T(_("Show Highlight's Notes: %1"), capitalizeFirstLetter(current_state))
		end,
		enabled = true,
		sub_item_table = {
			{
				text = _("Disable"),
				radio = true,
				checked_func = function()
					return config.read(K.notes.option.mode) == "disable"
				end,
				callback = function()
					config.write(K.notes.option.mode, "disable")
				end,
			},
			{
				text = _("Full"),
				radio = true,
				checked_func = function()
					return config.read(K.notes.option.mode) == "full"
				end,
				callback = function()
					config.write(K.notes.option.mode, "full")
				end,
			},
			{
				text = _("Short"),
				radio = true,
				checked_func = function()
					return config.read(K.notes.option.mode) == "short"
				end,
				callback = function()
					config.write(K.notes.option.mode, "short")
				end,
			},
			{
				text_func = function()
					return T(
							_("Character limit for short notes: %1"),
							config.read(K.notes.option.limit) or 70
					)
				end,
				enabled_func = function()
					return config.read(K.notes.option.mode) == "short"
				end,
				keep_menu_open = true,
				callback = function(touchmenu_instance)
					local ShortNoteLimitSpin =
					require("widgets.short_note_limit_spin")

					ShortNoteLimitSpin.show(
							config.read(K.notes.option.limit) or 70,
							function(new_value)
								config.write(K.notes.option.limit, new_value)
								touchmenu_instance:updateItems()
							end
					)
				end,

			},
		},
	}
end

return { buildMenuShowHighlightNotes = buildMenuShowHighlightNotes }
