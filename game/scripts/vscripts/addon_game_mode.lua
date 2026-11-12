-- RIFT ARENA bootstrap. Keep this file small: it only links modifiers and starts
-- the game mode. All systems live under rift/.

RIFT_MODIFIERS = {
  "modifier_rift_damage_tracker",
  "modifier_rift_spawn_shield",
  "modifier_rift_attack_probe",
  "modifier_rift_relic_carrier",
  "modifier_rift_upgrade_stats",
}

-- Called at file scope and again in Activate(): the first in-game run showed
-- "Attempted to create unknown modifier type" for every modifier linked only at file scope.
function RiftLinkModifiers(verbose)
  for _, name in ipairs(RIFT_MODIFIERS) do
    local r = LinkLuaModifier(name, "rift/modifiers/" .. name, LUA_MODIFIER_MOTION_NONE)
    if verbose then print("[RIFT][INFO][MODS] link " .. name .. " -> " .. tostring(r)) end
  end
end

RiftLinkModifiers(false)

function Precache(context)
  PrecacheUnitByNameSync("npc_dota_hero_phantom_assassin", context)
end

function Activate()
  RiftLinkModifiers(true)
  local GameMode = require("rift.engine.game_mode")
  GameRules.RiftArena = GameMode.new()
  GameRules.RiftArena:Activate()
end
