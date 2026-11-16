-- RIFT ARENA bootstrap. Keep this file small: it only links modifiers and starts
-- the game mode. All systems live under rift/.

local ModifierList = require("rift.modifier_list")

-- Server-side links (addon_init.lua links on both VMs; linking twice is harmless).
ModifierList.link(false)

function Precache(context)
  local expansion = require("rift.data.expansion")
  for _, hero in ipairs(expansion.heroes) do PrecacheUnitByNameSync(hero.unit, context) end
  for _, d in pairs(expansion.abilities) do
    PrecacheResource("particle", d.particle, context)
    if d.wave_particle then PrecacheResource("particle",d.wave_particle,context) end
  end
  PrecacheResource("particle", "particles/ui_mouseactions/ping_world.vpcf", context)
  PrecacheUnitByNameSync("npc_dota_hero_phantom_assassin", context)
  PrecacheUnitByNameSync("npc_dota_hero_templar_assassin", context)
  PrecacheUnitByNameSync("npc_dota_hero_legion_commander", context)
  PrecacheUnitByNameSync("npc_dota_hero_nevermore", context)
  PrecacheResource("particle", require("rift.data.hero_balance").sf.requiem_physical.wings_particle, context)
  PrecacheResource("particle", require("rift.data.hero_balance").sf.requiem_physical.sphere_particle, context)
  PrecacheResource("particle", require("rift.data.hero_balance").sf.requiem_physical.sphere_projectile, context)
  PrecacheResource("particle", "particles/items_fx/cyclone.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_templar_assassin/templar_assassin_psi_blade.vpcf", context)
  PrecacheResource("particle", "particles/items_fx/harpoon_pull.vpcf", context)
  PrecacheUnitByNameSync("npc_rift_ta_crystal", context)
  PrecacheUnitByNameSync("npc_rift_lc_champion", context)
  PrecacheUnitByNameSync("npc_rift_lc_statue", context)
  PrecacheResource("particle","particles/units/heroes/hero_templar_assassin/templar_assassin_refraction.vpcf",context)
  PrecacheResource("particle", require("rift.data.hero_balance").lc.statue.arrow_particle, context)
  PrecacheResource("particle", require("rift.data.hero_balance").lc.courage_physical.effect, context)
  PrecacheResource("particle", require("rift.data.hero_balance").lc.courage_physical.effect_target, context)
  PrecacheResource("particle", require("rift.data.hero_balance").ta.meld_physical.effect, context)
  PrecacheResource("particle", require("rift.data.hero_balance").ta.meld_physical.projectile, context)
  local pa = require("rift.data.hero_balance").pa
  PrecacheUnitByNameSync(pa.execution_physical.spirit_unit, context)
  for _, path in ipairs({ pa.execution_physical.spirit_particle, pa.storm_magical.dagger_particle,
                          pa.storm_magical.chain_particle,pa.execution_physical.spirit_ambient,
                          pa.execution_physical.spirit_impact }) do
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
