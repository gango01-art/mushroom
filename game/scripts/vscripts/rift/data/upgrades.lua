-- Regular upgrades (common / rare / epic). Ultimate directions live in
-- ultimate_directions.lua and are never part of this pool.
-- required_direction: "any" | "physical" | "magical" (direction-specific entries
-- appear only after the player's direction is confirmed).
-- status: only "implemented" entries can be offered. "planned" = data only.
-- All numbers are HYPOTHESIS unless marked otherwise.

local function U(t)
  t.type = "regular"
  t.prerequisites = t.prerequisites or {}
  t.required_direction = t.required_direction or "any"
  t.tags = t.tags or {}
  t.loc_name = t.loc_name or ("rift_up_" .. t.id)
  t.loc_desc = t.loc_desc or ("rift_up_" .. t.id .. "_desc")
  t.status = t.status or "planned"
  return t
end

return {
  -- Phantom Assassin --------------------------------------------------------
  U{ id = "pa_keen_edge", hero = "npc_dota_hero_phantom_assassin", rarity = "common", tags = { "attack" },
     max_rank = 3, values_by_rank = { attack_damage = { 12, 20, 28 } }, effect_handler = "stat_bonus",
     icon = "phantom_assassin_phantom_strike" },
  U{ id = "pa_veil_step", hero = "npc_dota_hero_phantom_assassin", rarity = "common", tags = { "mobility" },
     max_rank = 2, values_by_rank = { move_speed = { 15, 25 } }, effect_handler = "stat_bonus",
     icon = "phantom_assassin_blur" },
  U{ id = "pa_dagger_whet", hero = "npc_dota_hero_phantom_assassin", rarity = "common", tags = { "dagger" },
     max_rank = 2, values_by_rank = { cooldown_reduction = { 0.6, 1.2 } }, effect_handler = "ability_cooldown_flat",
     ability = "phantom_assassin_stifling_dagger", icon = "phantom_assassin_stifling_dagger" },
  U{ id = "pa_shadow_guard", hero = "npc_dota_hero_phantom_assassin", rarity = "common", tags = { "defense" },
     max_rank = 2, values_by_rank = { armor = { 3, 5 } }, effect_handler = "stat_bonus",
     icon = "phantom_assassin_blur" },
  U{ id = "pa_bloodletter", hero = "npc_dota_hero_phantom_assassin", rarity = "rare", tags = { "crit" },
     required_direction = "physical", max_rank = 2, values_by_rank = { crit_chance_bonus = { 4, 7 } },
     effect_handler = "pa_crit_chance_bonus", icon = "phantom_assassin_coup_de_grace" },
  U{ id = "pa_spirit_haste", hero = "npc_dota_hero_phantom_assassin", rarity = "rare", tags = { "spirit" },
     required_direction = "physical", max_rank = 2, values_by_rank = { spirit_cooldown_reduction = { 2, 4 } },
     effect_handler = "pa_spirit_cooldown", icon = "phantom_assassin_coup_de_grace" },
  U{ id = "pa_static_edge", hero = "npc_dota_hero_phantom_assassin", rarity = "rare", tags = { "chain" },
     required_direction = "magical", max_rank = 2, values_by_rank = { chain_damage_bonus = { 60, 120 } },
     effect_handler = "pa_chain_damage", icon = "phantom_assassin_stifling_dagger" },
  U{ id = "pa_conductive_blade", hero = "npc_dota_hero_phantom_assassin", rarity = "epic", tags = { "chain" },
     required_direction = "magical", max_rank = 1, values_by_rank = { chain_chance_bonus = { 0.05 } },
     prerequisites = { "pa_static_edge" }, effect_handler = "pa_chain_chance", icon = "phantom_assassin_stifling_dagger" },

  -- Universal ---------------------------------------------------------------
  U{ id = "u_vitality", hero = "universal", rarity = "common", tags = { "defense" }, max_rank = 3,
     values_by_rank = { health = { 150, 250, 350 } }, effect_handler = "stat_bonus", icon = "item_vitality_booster" },
  U{ id = "u_focus", hero = "universal", rarity = "common", tags = { "mana" }, max_rank = 2,
     values_by_rank = { mana = { 120, 200 } }, effect_handler = "stat_bonus", icon = "item_energy_booster" },
  U{ id = "u_swift_hands", hero = "universal", rarity = "common", tags = { "attack" }, max_rank = 3,
     values_by_rank = { attack_speed = { 15, 25, 35 } }, effect_handler = "stat_bonus", icon = "item_gloves" },
  U{ id = "u_arcane_edge", hero = "universal", rarity = "common", tags = { "spell" }, max_rank = 3,
     values_by_rank = { spell_amp = { 6, 10, 14 } }, effect_handler = "stat_bonus", icon = "item_kaya" },
  U{ id = "u_iron_skin", hero = "universal", rarity = "common", tags = { "defense" }, max_rank = 2,
     values_by_rank = { armor = { 2, 4 } }, effect_handler = "stat_bonus", icon = "item_chainmail" },
  U{ id = "u_quick_feet", hero = "universal", rarity = "common", tags = { "mobility" }, max_rank = 2,
     values_by_rank = { move_speed = { 12, 20 } }, effect_handler = "stat_bonus", icon = "item_boots" },
  U{ id = "u_mending", hero = "universal", rarity = "common", tags = { "sustain" }, max_rank = 3,
     values_by_rank = { health_regen = { 4, 7, 10 } }, effect_handler = "stat_bonus", icon = "item_ring_of_health" },
  U{ id = "u_steadfast", hero = "universal", rarity = "rare", tags = { "defense" }, max_rank = 2,
     values_by_rank = { status_resistance = { 8, 14 } }, effect_handler = "stat_bonus", icon = "item_sange" },
}
