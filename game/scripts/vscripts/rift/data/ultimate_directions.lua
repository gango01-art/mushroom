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
    ultimate_ability_id = "phantom_assassin_coup_de_grace", -- VERIFY in installed client
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
      crit_multiplier = "native:crit_bonus",       -- from Coup de Grace rank, VERIFY key
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
}
