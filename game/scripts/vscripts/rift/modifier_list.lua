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
  "modifier_rift_ta_no_attack",
  "modifier_rift_ta_refraction",
  "modifier_rift_ta_dash",
  "modifier_rift_ta_trap_slow",
  "modifier_rift_sf_spheres",
  "modifier_rift_sf_rings",
  "modifier_rift_sf_fear",
  "modifier_rift_pa_dagger_slow",
  "modifier_rift_pa_spirit",
  "modifier_rift_lc_throne",
  "modifier_rift_lc_champion",
  "modifier_rift_lc_duel_damage",
}

-- Modifiers that need a motion type other than NONE (engine constant name).
M.MOTION = { modifier_rift_ta_dash = "LUA_MODIFIER_MOTION_HORIZONTAL" }

function M.link(verbose)
  for _, name in ipairs(M) do
    local motion = M.MOTION[name] and _G[M.MOTION[name]] or LUA_MODIFIER_MOTION_NONE
    LinkLuaModifier(name, "rift/modifiers/" .. name, motion)
    if verbose then print("[RIFT][INFO][MODS] link " .. name .. (IsServer() and " (server)" or " (client)")) end
  end
end

return M
