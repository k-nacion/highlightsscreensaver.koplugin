local K = {}

------------------------------------------------------------
-- Namespace root (PLUGIN)
------------------------------------------------------------
K.NAMESPACE = "highlights_screensaver_"

------------------------------------------------------------
-- KOReader default screensaver keys
------------------------------------------------------------
K.koreader = {
    screensaver_type = "screensaver_type",
    screensaver = {
        show_message = "screensaver_show_message", -- Show or hide text entirely
        message = "screensaver_message", -- Main sleep message
        exit_message = "screensaver_exit_message", -- Message when exiting sleep
        container = "screensaver_message_container", -- "box" or "banner"
        vertical_position = "screensaver_message_vertical_position", -- Vertical position 0-100%
        alpha = "screensaver_message_alpha", -- Opacity 0-100%
        background = "screensaver_msg_background", -- Background behind text
        hide_fallback = "screensaver_hide_fallback_msg", -- Hide fallback message
    },
    is_night_mode = "night_mode",
}


------------------------------------------------------------
-- Plugin-owned screensaver message settings
------------------------------------------------------------
K.screensaver_message = {
    width = {
        mode = "message_width_mode",
        custom_mode = "message_custom_width",
    },

    layout = {
        font_size = "message_layout_font_size",
        line_spacing = "message_layout_line_spacing",
        alignment = "message_layout_alignment",
        padding = "message_layout_padding",
        margin = "message_layout_margin",
    },
}

------------------------------------------------------------
-- Highlight Layout (READER SETTINGS)
------------------------------------------------------------
K.highlights = {
    alignment = "hs_text_alignment",
    justified = "hs_justified",
    line_height = "hs_line_height",
    width_percent = "hs_width_percent",
    font_size_base = "hs_font_size_base",
    font_size_min = "hs_font_size_min",
    border_spacing = "hs_border_spacing",
}

------------------------------------------------------------
-- Notes (READER SETTINGS)
------------------------------------------------------------
K.notes = {
    sync_with_highlights = "ns_sync_with_highlights",

    alignment = "ns_text_alignment",
    justified = "ns_justified",
    line_height = "ns_line_height",
    width_percent = "ns_width_percent",
    font_size_base = "ns_font_size_base",
    font_size_min = "ns_font_size_min",

    option = {
        mode = "show_notes_option",
        limit = "show_notes_limit",
    },
}

K.display = {
    orientation = "highlights_orientation",
}

------------------------------------------------------------
-- Directory Picker (PLUGIN)
------------------------------------------------------------
K.directory_picker = {
    last_path = "directory_picker_last_path",
}


return K
