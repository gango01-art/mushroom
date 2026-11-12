-- RIFT ARENA bootstrap. Keep this file small: it only links modifiers and starts
-- the game mode. All systems live under rift/.

local ModifierList = require("rift.modifier_list")

-- Server-side links (addon_init.lua links on both VMs; linking twice is harmless).
ModifierList.link(false)

function Precache(context)
  PrecacheUnitByNameSync("npc_dota_hero_phantom_assassin", context)
end

function Activate()
  ModifierList.link(true)
  local GameMode = require("rift.engine.game_mode")
  GameRules.RiftArena = GameMode.new()
  GameRules.RiftArena:Activate()
end
