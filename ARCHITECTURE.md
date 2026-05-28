# Architecture

> Highlights Screensaver Plugin for KOReader

## Overview

This plugin replaces KOReader's default screensaver with a randomly selected
book highlight, styled with configurable fonts, theme, and layout options.

## Module Graph

```
main.lua (entry point — WidgetContainer plugin)
│
├── core/screensaver_patch.lua    ← patches Screensaver.show()
│   ├── core/clipper.lua          ← random clipping selection & JSON persistence
│   ├── core/scan.lua             ← scans device for highlight metadata files
│   └── ui/screensaver_display.lua ← builds the ScreenSaverWidget
│       ├── ui/theme_helpers.lua   ← resolves fg/bg colors from theme + night mode
│       └── ui/message_widget.lua  ← optional box/banner message overlay
│
├── menu_builders/_menu_injector.lua ← patches dofile() to inject menu items
│   └── menu_builders/highlights_screensaver_menu.lua ← top-level menu
│       ├── menu_builders/scan_menu.lua
│       ├── menu_builders/theme.lua
│       ├── menu_builders/fonts_menu.lua
│       ├── menu_builders/orientation_menu.lua
│       ├── menu_builders/highlights_layout.lua
│       ├── menu_builders/notes_layout.lua
│       ├── menu_builders/highlight_notes_menu.lua
│       ├── menu_builders/disable_highlight_menu.lua
│       ├── menu_builders/import_quotes_menu.lua
│       └── menu_builders/sleep_screen_message_menu.lua
│
├── core/config/          ← configuration layer (facade pattern)
│   ├── init.lua          ← facade re-exporting all sub-modules
│   ├── defaults.lua      ← default values, Theme/Fonts constants
│   ├── settings.lua      ← hybrid read/write (KOReader settings ↔ plugin JSON)
│   └── persistence.lua   ← JSON config.json load/save with error boundaries
│
├── core/keys.lua         ← string key constants for all settings
├── core/logger.lua       ← thin logging wrapper
├── core/utils.lua        ← filesystem utilities (paths, dirs)
├── core/external_quotes.lua ← imports .txt quote files as clippings
│
├── widgets/              ← reusable UI components
│   ├── generic_spin.lua          ← configurable SpinWidget
│   ├── short_note_limit_spin.lua ← character-limit spinner
│   ├── directory_picker.lua      ← path chooser with persistence
│   └── directory_scanner.lua     ← .txt file scanner
│
└── vendor/
    └── sha2.lua          ← third-party SHA library (used for quote hashing)
```

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ Device goes to sleep                                            │
│   → KOReader calls Screensaver:show()                           │
│     → Our patch intercepts (if screensaver_type == "highlights")│
│       → scan.scanHighlights() (once per day)                    │
│       → clipper.getRandomClipping()                             │
│       → screensaver_display.buildHighlightsScreensaverWidget()  │
│         → theme_helpers.getThemeColors()                        │
│         → message_widget.build() (optional)                     │
│       → UIManager:show(widget)                                  │
│                                                                 │
│ If any error occurs → pcall catches it → og_show(self)          │
└─────────────────────────────────────────────────────────────────┘
```

## Configuration System

The plugin uses a **hybrid configuration approach**:

| Data                        | Storage             | Module              |
|-----------------------------|---------------------|---------------------|
| KOReader screensaver keys   | `G_reader_settings` | `settings.lua`      |
| Plugin highlight layout     | `G_reader_settings` | `settings.lua`      |
| Theme, fonts, directories   | `config.json`       | `persistence.lua`   |
| Default values              | In-memory           | `defaults.lua`      |

The `core/config/init.lua` facade exposes a unified API:
- `config.read(key)` / `config.write(key, value)` — hybrid routing
- `config.getTheme()` / `config.setTheme()` — JSON-persisted
- `config.getFonts()` / `config.setFonts()` — JSON-persisted

## Monkey-Patching Strategy

KOReader has no official plugin hooks for:
1. The screensaver display logic
2. The screensaver settings submenu

We work around this with two controlled patches:

1. **`Screensaver.show()`** — intercepted to add "highlights" mode
2. **`dofile()`** — intercepted to inject menu items when KOReader loads
   `screensaver_menu.lua`

Both patches are:
- Applied once in `init()` (plugin lifecycle)
- Guarded against double-application (`patched` flag)
- Wrapped in error boundaries (pcall fallback)

## Error Boundaries

Critical paths are wrapped in `pcall` to prevent plugin errors from
breaking the device:

| Location                    | Fallback Behavior                     |
|-----------------------------|---------------------------------------|
| `screensaver_patch.lua`     | Falls back to default screensaver     |
| `persistence.lua` (load)    | Returns default config                |
| `persistence.lua` (save)    | Logs warning, config not persisted    |

## Extension Points

To add a new menu item:
1. Create `menu_builders/your_feature_menu.lua`
2. Export `{ buildMenuYourFeature = buildMenuYourFeature }`
3. Require it in `highlights_screensaver_menu.lua` and add to the sub_item_table

To add a new config key:
1. Add the key string to `core/keys.lua`
2. Add a default value to `core/config/defaults.lua`
3. Use `config.read(K.your_key)` / `config.write(K.your_key, value)` anywhere

## Conventions

- **Module pattern**: All files use `local M = {} ... return M`
- **Docblocks**: Every file has a `--[[ ... ]]` header explaining purpose
- **Type annotations**: LuaLS `@class`, `@param`, `@return` on public APIs
- **No side effects at require time**: All initialization in `init()`
- **Vendor code**: Third-party libraries live in `vendor/` with README
