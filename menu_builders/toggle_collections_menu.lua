local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local clipper = require("core.clipper")
local _ = require("gettext")

local function buildMenuToggleCollections()
    return {
        text = _("Toggle Collections"),
        sub_item_table_func = function()
            local collections = clipper.getCollections()

            -- Sort collection names alphabetically
            local sorted_titles = {}
            for title, _ in pairs(collections) do
                table.insert(sorted_titles, title)
            end
            table.sort(sorted_titles, function(a, b)
                return a:lower() < b:lower()
            end)

            local items = {}

            -- "Enable All" option
            table.insert(items, {
                text = _("Enable All"),
                callback = function()
                    for _, title in ipairs(sorted_titles) do
                        clipper.setCollectionEnabled(title, true)
                    end
                    UIManager:show(InfoMessage:new{
                        text = _("All collections enabled."),
                        timeout = 2,
                    })
                end,
            })

            -- "Disable All" option
            table.insert(items, {
                text = _("Disable All"),
                callback = function()
                    for _, title in ipairs(sorted_titles) do
                        clipper.setCollectionEnabled(title, false)
                    end
                    UIManager:show(InfoMessage:new{
                        text = _("All collections disabled."),
                        timeout = 2,
                    })
                end,
                separator = true,
            })

            -- One checkbox entry per collection
            for _, title in ipairs(sorted_titles) do
                local info = collections[title]
                local display_text = title .. " (" .. info.total .. ")"

                table.insert(items, {
                    text = display_text,
                    checked_func = function()
                        -- Re-read to get current state
                        local current = clipper.getCollections()
                        local col = current[title]
                        if not col then return false end
                        return col.enabled_count == col.total
                    end,
                    callback = function()
                        -- Toggle: if all enabled -> disable all; otherwise -> enable all
                        local current = clipper.getCollections()
                        local col = current[title]
                        if not col then return end

                        local new_state = col.enabled_count ~= col.total
                        clipper.setCollectionEnabled(title, new_state)

                        local state_text = new_state and "enabled" or "disabled"
                        UIManager:show(InfoMessage:new{
                            text = string.format("%s: %s (%d quotes)", title, state_text, col.total),
                            timeout = 2,
                        })
                    end,
                })
            end

            if #sorted_titles == 0 then
                table.insert(items, {
                    text = _("No collections found"),
                    enabled = false,
                })
            end

            return items
        end,
    }
end

return {
    buildMenuToggleCollections = buildMenuToggleCollections,
}
