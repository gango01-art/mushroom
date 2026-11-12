-- RIFT ARENA bootstrap. Keep this file small: it only links modifiers and starts
-- the game mode. All systems live under rift/.

LinkLuaModifier("modifier_rift_damage_tracker", "rift/modifiers/modifier_rift_damage_tracker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rift_spawn_shield", "rift/modifiers/modifier_rift_spawn_shield", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rift_upgrade_stats", "rift/modifiers/modifier_rift_upgrade_stats", LUA_MODIFIER_MOTION_NONE)

function Precache(context)
  PrecacheUnitByNameSync("npc_dota_hero_phantom_assassin", context)
end

function Activate()
  local GameMode = require("rift.engine.game_mode")
  GameRules.RiftArena = GameMode.new()
  GameRules.RiftArena:Activate()
end
