-- Runs in both the client and the server Lua VM (unlike addon_game_mode.lua,
-- which is server only). Linking here lets the client know our modifier classes
-- (icons, transmitter data, client-side properties). See KNOWN_ISSUES 13.
require("rift.modifier_list").link(true)
