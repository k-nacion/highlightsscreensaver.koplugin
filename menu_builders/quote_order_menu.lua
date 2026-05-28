local _ = require("gettext")
local config = require("core.config")
local K = require("core.keys")

local function buildMenuQuoteOrder()
    return {
        text = _("Quote order"),
        sub_item_table = {
            {
                text = _("Random"),
                checked_func = function()
                    return (config.read(K.display.quote_order) or "random") == "random"
                end,
                callback = function()
                    config.write(K.display.quote_order, "random")
                end,
            },
            {
                text = _("Sequential"),
                checked_func = function()
                    return config.read(K.display.quote_order) == "sequential"
                end,
                callback = function()
                    config.write(K.display.quote_order, "sequential")
                end,
            },
        },
    }
end

return {
    buildMenuQuoteOrder = buildMenuQuoteOrder,
}
