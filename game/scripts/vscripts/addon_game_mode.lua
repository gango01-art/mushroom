-- RIFT ARENA bootstrap. Keep this file small: it only links modifiers and starts
-- the game mode. All systems live under rift/.

local ModifierList = require("rift.modifier_list")

-- Server-side links (addon_init.lua links on both VMs; linking twice is harmless).
ModifierList.link(false)

function Precache(context)
  PrecacheUnitByNameSync("npc_dota_hero_phantom_assassin", context)
  PrecacheUnitByNameSync("npc_dota_hero_templar_assassin", context)
  PrecacheUnitByNameSync("npc_rift_ta_crystal", context)
  PrecacheUnitByNameSync("npc_rift_lc_champion", context)
  local pa = require("rift.data.hero_balance").pa
  PrecacheUnitByNameSync(pa.execution_physical.spirit_unit, context)
  for _, path in ipairs({ pa.execution_physical.spirit_particle, pa.storm_magical.dagger_particle,
                          pa.storm_magical.chain_particle }) do
    PrecacheResource("particle", path, context)
  end
  -- Dev-only test dummies (rift_spawn_dummy) are heroes so hero-only effects can hit them.
  if IsInToolsMode and IsInToolsMode() then
    PrecacheUnitByNameSync("npc_dota_hero_axe", context)
  end
end

function Activate()
  ModifierList.link(true)
  local GameMode = require("rift.engine.game_mode")
  GameRules.RiftArena = GameMode.new()
  GameRules.RiftArena:Activate()
end
