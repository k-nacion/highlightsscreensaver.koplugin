# Vendor Dependencies

Third-party libraries included in this plugin. Do not modify directly.

## sha2.lua

- **Source:** https://github.com/Egor-Skriptunoff/pure_lua_SHA
- **Version:** 12 (2022-02-23)
- **License:** MIT
- **Used for:** SHA-1 hashing of external quotes for deduplication
- **Used by:** `core/external_quotes.lua`
- **Functions used:** `sha.sha1()`

This is a pure Lua implementation of various SHA hash functions.
Only `sha1()` is used by this plugin for generating short (12-char)
deterministic hash IDs for imported quotes.
