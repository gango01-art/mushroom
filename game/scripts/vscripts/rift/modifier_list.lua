-- Single list of our Lua modifiers. Shared by addon_init.lua (client + server),
-- addon_game_mode.lua (server) and dev diagnostics. Globals defined in
-- addon_game_mode.lua are NOT visible to required modules (verified in Dota), so
-- the list lives in a module.
local M = {
  "modifier_rift_damage_tracker",
  "modifier_rift_spawn_shield",
  "modifier_rift_attack_probe",
  "modifier_rift_relic_carrier",
  "modifier_rift_upgrade_stats",
  "modifier_rift_ta_crystal",
  "modifier_rift_ta_meld",
  "modifier_rift_dummy",
}

function M.link(verbose)
  for _, name in ipairs(M) do
    LinkLuaModifier(name, "rift/modifiers/" .. name, LUA_MODIFIER_MOTION_NONE)
    if verbose then print("[RIFT][INFO][MODS] link " .. name .. (IsServer() and " (server)" or " (client)")) end
  end
end

return M
