-- Ultimate directions: exactly two per supported hero (physical + magical).
-- Values marked HYPOTHESIS are starting balance proposals; owner-given values are
-- marked OWNER and must not be changed silently.
-- "native:<special>" means: read the value from the installed ability KV at runtime
-- (never invent native numbers here).
-- status: "implemented" only when the engine handler exists AND both directions of
-- the hero are complete. A hero is selectable only if both are implemented.

return {
  {
    id = "pa_phantom_execution",
    hero_id = "npc_dota_hero_phantom_assassin",
    ultimate_ability_id = "phantom_assassin_coup_de_grace", -- verified OP-004 2026-11-12
    learn_trigger_adapter = "first_point_in_ultimate",
    direction = "physical",
    affected_abilities = { "phantom_assassin_coup_de_grace" },
    preserved_effects = { "coup_de_grace_native_crit" },
    replaced_effects = {},
    values_by_ultimate_rank = {
      spirit_range = { 800, 800, 800 },            -- HYPOTHESIS
      spirit_speed = { 900, 900, 900 },            -- HYPOTHESIS
      cooldown = { 24, 20, 16 },                   -- HYPOTHESIS
      mana_cost = { 80, 100, 120 },                -- HYPOTHESIS
      crit_multiplier = "native:crit_bonus",       -- verified key: 200/325/450 % (OP-004)
    },
    active_handler = "pa_phantom_spirit",
    passive_handler = nil,
    default_on_timeout = true,
    transfer_policy = "keep_rank_keep_cooldown",
    item_proc_policy = "no_item_procs",
    resources = { projectile_particle = "VERIFY: grimstroke-like spirit particle" },
    loc_name = "rift_dir_pa_phantom_execution",
    loc_desc = "rift_dir_pa_phantom_execution_desc",
    icon = "phantom_assassin_coup_de_grace",
    status = "planned",
  },
  {
    id = "pa_storm_daggers",
    hero_id = "npc_dota_hero_phantom_assassin",
    ultimate_ability_id = "phantom_assassin_coup_de_grace",
    learn_trigger_adapter = "first_point_in_ultimate",
    direction = "magical",
    affected_abilities = { "phantom_assassin_coup_de_grace", "phantom_assassin_stifling_dagger" },
    preserved_effects = { "stifling_dagger_base_effects" },
    replaced_effects = { "coup_de_grace_native_crit" },
    values_by_ultimate_rank = {
      extra_targets = { 1, 1, 1 },                 -- OWNER: max 2 different targets per cast
      chain_chance = { 0.20, 0.20, 0.20 },         -- OWNER: 20% at rank 1; ranks 2-3 HYPOTHESIS keep 20%
      chain_damage = { 300, 380, 460 },            -- OWNER: 300 at rank 1; 380/460 HYPOTHESIS
      second_target_radius = { 600, 600, 600 },    -- HYPOTHESIS
      cast_context_seconds = { 3, 3, 3 },          -- HYPOTHESIS: max wait for both daggers
    },
    active_handler = nil,
    passive_handler = "pa_storm_daggers",
    default_on_timeout = false,
    transfer_policy = "keep_rank_keep_cooldown",
    item_proc_policy = "item_effects_unchanged",
    resources = { chain_particle = "VERIFY: lightning chain particle" },
    loc_name = "rift_dir_pa_storm_daggers",
    loc_desc = "rift_dir_pa_storm_daggers_desc",
    icon = "phantom_assassin_stifling_dagger",
    status = "planned",
  },

  -- Legion Commander / Shadow Fiend / Templar Assassin: docs/BRIEF_HEROES_LC_SF_TA.md.
  -- Numbers live in rift/data/hero_balance.lua (balance_ref), never duplicated here.
  -- ultimate_ability_id values verified in the installed client (OP-006, 2026-11-12).
  {
    id = "lc_duel_physical", hero_id = "npc_dota_hero_legion_commander",
    ultimate_ability_id = "legion_commander_duel", learn_trigger_adapter = "first_point_in_ultimate",
    direction = "physical", display_base = "Duel",
    affected_abilities = { "legion_commander_duel" },
    preserved_effects = {}, replaced_effects = { "duel_native" },
    balance_ref = "lc.duel_physical", active_handler = "lc_champion_duel",
    default_on_timeout = true, transfer_policy = "keep_rank_keep_cooldown",
    loc_name = "rift_dir_lc_duel_physical", loc_desc = "rift_dir_lc_duel_physical_desc",
    icon = "legion_commander_duel", status = "planned",
  },
  {
    id = "lc_duel_magical", hero_id = "npc_dota_hero_legion_commander",
    ultimate_ability_id = "legion_commander_duel", learn_trigger_adapter = "first_point_in_ultimate",
    direction = "magical", display_base = "Duel",
    affected_abilities = { "legion_commander_duel", "legion_commander_moment_of_courage" },
    preserved_effects = {}, replaced_effects = { "duel_native", "third_ability_replaced_by_statue" },
    balance_ref = "lc.duel_magical", passive_handler = "lc_spell_amp_duel",
    default_on_timeout = false, transfer_policy = "keep_rank_keep_cooldown",
    loc_name = "rift_dir_lc_duel_magical", loc_desc = "rift_dir_lc_duel_magical_desc",
    icon = "legion_commander_duel", status = "planned",
  },
  {
    id = "sf_requiem_physical", hero_id = "npc_dota_hero_nevermore",
    ultimate_ability_id = "nevermore_requiem", learn_trigger_adapter = "first_point_in_ultimate",
    direction = "physical", display_base = "Requiem of Souls",
    affected_abilities = { "nevermore_requiem", "nevermore_shadowraze1", "nevermore_shadowraze2", "nevermore_shadowraze3" },
    preserved_effects = { "shadowraze_magic_damage" }, replaced_effects = { "requiem_native_blast", "requiem_on_death" },
    balance_ref = "sf.requiem_physical", active_handler = "sf_red_spheres",
    default_on_timeout = true, transfer_policy = "keep_rank_keep_cooldown",
    loc_name = "rift_dir_sf_requiem_physical", loc_desc = "rift_dir_sf_requiem_physical_desc",
    icon = "nevermore_requiem", status = "planned",
  },
  {
    id = "sf_requiem_magical", hero_id = "npc_dota_hero_nevermore",
    ultimate_ability_id = "nevermore_requiem", learn_trigger_adapter = "first_point_in_ultimate",
    direction = "magical", display_base = "Requiem of Souls",
    affected_abilities = { "nevermore_requiem" },
    preserved_effects = { "requiem_native_blast", "requiem_on_death" }, replaced_effects = {},
    balance_ref = "sf.requiem_magical", active_handler = "sf_raze_rings",
    default_on_timeout = false, transfer_policy = "keep_rank_keep_cooldown",
    loc_name = "rift_dir_sf_requiem_magical", loc_desc = "rift_dir_sf_requiem_magical_desc",
    icon = "nevermore_requiem", status = "planned",
  },
  {
    id = "ta_crystal_physical", hero_id = "npc_dota_hero_templar_assassin",
    ultimate_ability_id = "templar_assassin_psionic_trap", learn_trigger_adapter = "first_point_in_ultimate",
    direction = "physical", display_base = "Psionic Crystal",
    affected_abilities = { "templar_assassin_psionic_trap", "templar_assassin_meld" },
    preserved_effects = { "refraction", "psi_blades_native" }, replaced_effects = { "psionic_trap", "meld_armor_reduction" },
    balance_ref = "ta.crystal_physical", active_handler = "ta_psionic_crystal",
    default_on_timeout = true, transfer_policy = "keep_rank_keep_cooldown",
    loc_name = "rift_dir_ta_crystal_physical", loc_desc = "rift_dir_ta_crystal_physical_desc",
    icon = "templar_assassin_psionic_trap", status = "planned",
  },
  {
    id = "ta_waves_magical", hero_id = "npc_dota_hero_templar_assassin",
    ultimate_ability_id = "templar_assassin_psionic_trap", learn_trigger_adapter = "first_point_in_ultimate",
    direction = "magical", display_base = "Psionic Trap",
    affected_abilities = { "templar_assassin_refraction", "templar_assassin_meld", "templar_assassin_psi_blades",
                           "templar_assassin_psionic_trap" },
    preserved_effects = { "refraction_defense" },
    replaced_effects = { "auto_attacks", "refraction_offense", "meld", "psi_blades_passive", "psionic_trap" },
    balance_ref = "ta.waves_magical", active_handler = "ta_psi_waves",
    default_on_timeout = false, transfer_policy = "keep_rank_keep_cooldown",
    loc_name = "rift_dir_ta_waves_magical", loc_desc = "rift_dir_ta_waves_magical_desc",
    icon = "templar_assassin_psi_blades", status = "planned",
  },
}
