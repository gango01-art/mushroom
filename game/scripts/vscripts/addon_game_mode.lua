-- RIFT ARENA bootstrap. Keep this file small: it only links modifiers and starts
-- the game mode. All systems live under rift/.

local ModifierList = require("rift.modifier_list")

-- Server-side links (addon_init.lua links on both VMs; linking twice is harmless).
ModifierList.link(false)

function Precache(context)
  PrecacheUnitByNameSync("npc_dota_hero_phantom_assassin", context)
  PrecacheUnitByNameSync("npc_rift_ta_crystal", context)
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
