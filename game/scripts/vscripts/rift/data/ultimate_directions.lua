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
    balance_ref = "pa.execution_physical",
    -- Native Coup de Grace stays leveled and hidden (native crits preserved); the R button becomes
    -- the active spirit. Its level follows the custom ability (abilities/pa_phantom_execution).
    swaps = { { from = "phantom_assassin_coup_de_grace", to = "pa_phantom_execution" } },
    active_handler = "pa_phantom_spirit",
    passive_handler = nil,
    default_on_timeout = true,
    transfer_policy = "keep_rank_keep_cooldown",
    item_proc_policy = "no_item_procs",
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
    balance_ref = "pa.storm_magical",
    -- Native crit off (incl. dagger crit): Coup de Grace goes to level 0. The dagger is replaced by
    -- a custom one that owns its projectiles (cast ids, 2 targets); the hidden native dagger stays
    -- leveled as the value source (talents included).
    swaps = { { from = "phantom_assassin_coup_de_grace", to = "pa_storm_charge", disable_from = true },
              { from = "phantom_assassin_stifling_dagger", to = "pa_storm_dagger" } },
    active_handler = nil,
    passive_handler = "pa_storm_daggers",
    default_on_timeout = false,
    transfer_policy = "keep_rank_keep_cooldown",
    item_proc_policy = "item_effects_unchanged",
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
    -- native Requiem (incl. on-death release) is fully disabled in this direction (prototype setting)
    swaps = { { from = "nevermore_requiem", to = "sf_requiem_physical", disable_from = true } },
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
    modifiers = { "modifier_rift_sf_rings" },  -- listens for successful manual Requiem casts
    default_on_timeout = false, transfer_policy = "keep_rank_keep_cooldown",
    loc_name = "rift_dir_sf_requiem_magical", loc_desc = "rift_dir_sf_requiem_magical_desc",
    icon = "nevermore_requiem", status = "planned",
  },
  {
    id = "ta_crystal_physical", hero_id = "npc_dota_hero_templar_assassin",
    ultimate_ability_id = "templar_assassin_psionic_trap", learn_trigger_adapter = "first_point_in_ultimate",
    direction = "physical", display_base = "Psionic Crystal",
    affected_abilities = { "templar_assassin_psionic_trap", "templar_assassin_meld" },
    preserved_effects = { "refraction_native", "psi_blades_native" }, replaced_effects = { "psionic_trap", "meld_armor_reduction" },
    balance_ref = "ta.crystal_physical", active_handler = "ta_psionic_crystal",
    swaps = { { from = "templar_assassin_psionic_trap", to = "ta_psionic_crystal" },
              { from = "templar_assassin_meld", to = "ta_meld_physical" } },
    -- native trap sub-abilities have no use without Psionic Trap: removed from the bar (owner request)
    remove = { "templar_assassin_trap", "templar_assassin_trap_teleport" },
    -- Refraction and Psi Blades untouched (OP-018: Psi Blades must stay visible)
    order = { "templar_assassin_refraction", "ta_meld_physical", "templar_assassin_psi_blades",
              { name = "ta_psionic_crystal", slot = 5 } },
    -- Meld replacement (no armor reduction, bigger bonus) is listed below once implemented;
    -- the direction stays "planned" until every part is verified in Dota.
    default_on_timeout = true, transfer_policy = "keep_rank_keep_cooldown",
    loc_name = "rift_dir_ta_crystal_physical", loc_desc = "rift_dir_ta_crystal_physical_desc",
    icon = "templar_assassin_psionic_trap", status = "implemented",
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
    -- Level/cooldown come from the native each one replaces (native Refraction is added to TA's
    -- base kit, data/hero_kits.lua).
    swaps = { { from = "templar_assassin_refraction", to = "ta_refraction_magical" },
              { from = "templar_assassin_meld", to = "ta_meld_dash" },
              { from = "templar_assassin_psi_blades", to = "ta_psi_wave" },
              { from = "templar_assassin_psionic_trap", to = "ta_psionic_blast" } },
    remove = { "templar_assassin_trap", "templar_assassin_trap_teleport" },
    order = { "ta_refraction_magical", "ta_meld_dash", "ta_psi_wave", { name = "ta_psionic_blast", slot = 5 } },
    modifiers = { "modifier_rift_ta_no_attack" },
    excluded_upgrade_tags = { "attack", "crit", "lifesteal_attack" },  -- no normal attacks in this direction
    default_on_timeout = false, transfer_policy = "keep_rank_keep_cooldown",
    loc_name = "rift_dir_ta_waves_magical", loc_desc = "rift_dir_ta_waves_magical_desc",
    icon = "templar_assassin_psi_blades", status = "implemented",
  },
}
