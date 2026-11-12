-- Balance for Legion Commander, Shadow Fiend, Templar Assassin directions.
-- Source: docs/BRIEF_HEROES_LC_SF_TA.md.
-- Provenance tags in comments:  DR = DESIGN_REQUIRED (owner, do not change silently)
--                               PD = PLAYTEST_DEFAULT (starting test value)
-- Every array states its index:  [ult] = ultimate rank 1..3, [q]/[w]/[e] = ability
-- rank 1..4, [ring] = sequential ring 1..3, [shot] = statue shot 1..4.
-- Pure data, no engine globals.

local B = {}

B.lc = {
  duel_physical = {
    max_seconds = 10,                         -- DR
    per_second = { 0.8, 1.1, 1.4 },           -- [ult] DR permanent damage per live second
    victory_multiplier = 1.5,                 -- DR victory total = per_second * max_payouts * 1.5
    max_payouts = 10,                         -- PD (one per second, first at t>=1)
    hit_window = 2,                           -- PD payout needs a champion hit on target in last 2 s
    permanent_cap = { 100, 140, 180 },        -- [ult] PD cap of permanent damage from this direction
    victory_min_damage_fraction = 0.20,       -- PD champion damage to target, of target max HP
    champion_death_penalty_fraction = 0.30,   -- DR of LC max HP, pure damage
    champion_death_stun = 1.0,                -- DR seconds
    champion_attack_speed_factor = 0.90,      -- DR of LC effective attacks per second
    leash_distance = 900,                     -- PD from throne
    leash_grace = 1.0,                        -- PD seconds beyond leash before break
    cooldown = { 85, 75, 65 },                -- [ult] PD from successful summon
    mana = { 150, 175, 200 },                 -- [ult] PD
    cast_range = 550,                         -- PD
  },
  duel_magical = {
    base_spell_amp = { 3, 5, 7 },             -- [ult] PD percent
    cap_spell_amp = { 10, 15, 20 },           -- [ult] PD (DR: up to 20)
    per_kill = 1.0,                           -- DR percentage points per real enemy hero kill
    per_assist = 0.5,                         -- PD
    break_policy = "suspend",                 -- PD: Break disables bonus, keeps earned points
  },
  statue = {                                  -- replaces LC third ability in magical direction
    lifetime = 10,                            -- DR
    shot_times = { 0.5, 3.5, 6.5, 9.5 },      -- [shot] PD (DR: one arrow per 3 s)
    cooldown = 25,                            -- DR
    cdr_per_hit = 2,                          -- DR seconds per arrow hit on a real enemy hero
    arrow_damage = { 60, 90, 120, 150 },      -- [e] PD magic spell damage
    health = { 400, 550, 700, 850 },          -- [e] PD
    armor = 0,                                -- PD
    magic_resistance = 25,                    -- PD percent
    cast_range = 500,                         -- PD
    attack_range = 650,                       -- PD
    mana = 90,                                -- PD
  },
}

B.sf = {
  requiem_physical = {
    duration = 15,                            -- DR
    spheres = 4,                              -- DR start and max
    sphere_damage_fraction = 0.60,            -- DR of attack damage (no crit multiplier)
    sphere_regen = { 1.8, 1.65, 1.5 },        -- [ult] PD seconds per sphere (DR: 1.5 at max rank)
    raze_bonus_fraction = { 0.40, 0.60, 0.80 },-- [ult] PD of attack damage, physical (DR: 80% at max)
    cooldown = { 80, 70, 60 },                -- [ult] PD
    mana = { 150, 175, 200 },                 -- [ult] PD
    -- Visuals (DR: wings + red spheres). Paths must be found in Asset Browser (OP-016); "" = none yet.
    wings_particle = "",
    sphere_particle = "",
  },
  requiem_magical = {
    ring_radius = { 300, 500, 700 },          -- [ring] PD (NOT ultimate ranks)
    ring_time = { 0.6, 1.2, 1.8 },            -- [ring] PD seconds after Requiem release
    telegraph_lead = 0.4,                     -- PD
    ring_damage = { 70, 100, 130 },           -- [ult] PD magic damage per ring
    immune_fear = { 0.6, 0.8, 1.0 },          -- [ult] PD fear through debuff immunity, once per cast
    eruptions_per_ring = 8,                   -- PD
    eruption_radius = 120,                    -- PD
    cooldown = { 110, 100, 90 },              -- [ult] PD (native Requiem cooldown is kept in this prototype)
    mana = { 150, 175, 200 },                 -- [ult] PD (native mana kept; see KNOWN_ISSUES)
    requiem_radius = 1000,                    -- native requiem_radius (OP-006): immune-fear search radius
    eruption_particle = "particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf",  -- VERIFY (OP-017)
    telegraph_particle = "particles/ui_mouseactions/ping_world.vpcf",                      -- VERIFY (OP-017)
  },
}

B.ta = {
  crystal_physical = {
    radius = { 320, 380, 460 },               -- [ult] DR
    cooldown = { 10, 9, 8 },                  -- [ult] DR
    durability = 3,                           -- DR
    lifetime = 6,                             -- PD
    mana = 60,                                -- PD
    -- damage coefficient: Psi Blades special "attack_spill_pct" / 100 at runtime (70/80/90/100 by E rank,
    -- verified OP-006) - DR. No own coefficient.
  },
  meld_physical = {
    bonus_damage = { 100, 160, 220, 280 },    -- [w] PD, armor reduction removed (DR)
    cooldown = { 11, 9, 7, 5 },               -- [w] native copy (OP-006 dump)
    mana = { 35, 40, 45, 50 },                -- [w] native copy (OP-006 dump)
  },
  waves_magical = {
    length = 700,                             -- PD
    width = 180,                              -- PD full width (half-width 90 for APIs taking radius)
    speed = 1000,                             -- PD
    intellect_scaling = 0.60,                 -- PD proposal, not owner value
    q_base = 120,                             -- DR
    q_cooldown = { 16, 14, 12, 10 },          -- [q] PD
    q_mana = 80,                              -- PD
    w_base = 120,                             -- DR
    w_dash = { 250, 300, 350, 400 },          -- [w] PD
    w_cooldown = { 10, 9, 8, 7 },             -- [w] PD
    w_mana = 60,                              -- PD
    e_base = { 120, 140, 160, 180 },          -- [e] DR
    e_cooldown = { 6, 5, 4, 3 },              -- [e] PD
    e_mana = 45,                              -- PD
  },
  refraction_magical = {                      -- custom Q (Refraction is not in TA's kit in this Dota version)
    instances = { 3, 4, 5, 6 },               -- [q] copy of templar_assassin_refraction data (OP-006)
    shield_per_instance = 30,                 -- copy of native data: damage blocked per instance
    duration = 17,                            -- copy of native data
  },
  trap_magical = {
    cast_range = 700,                         -- PD
    delay = 0.5,                              -- PD
    radius = 250,                             -- PD
    cooldown = { 14, 12, 10 },                -- [ult] PD
    mana = 90,                                -- PD
    damage = { 100, 160, 220 },               -- [ult] PD magic
    slow = { 30, 40, 50 },                    -- [ult] PD percent
    slow_duration = 3,                        -- PD
    -- trap_debuff_policy: only damage + slow above. Native silence/extra effects (Scepter/talents) excluded.
  },
  wave_particle = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf",   -- VERIFY (OP-015)
  trap_telegraph_particle = "particles/ui_mouseactions/ping_world.vpcf",              -- VERIFY (OP-015)
}

-- Phantom Assassin (docs/BRIEF.md 13). Native values are read from the installed abilities at
-- runtime; "native copy" numbers below are only fallbacks (OP-004 dump).
B.pa = {
  execution_physical = {
    range = 800,                              -- PD (BRIEF start value)
    speed = 900,                              -- PD (BRIEF start value)
    cooldown = { 24, 20, 16 },                -- [ult] PD
    mana = { 80, 100, 120 },                  -- [ult] PD
    crit_fallback = { 200, 325, 450 },        -- [ult] native copy of Coup de Grace crit_bonus (OP-004)
    -- VERIFY (OP-020): spirit-like tracking projectile; Grimstroke look is the visual target
    spirit_particle = "particles/units/heroes/hero_necrolyte/necrolyte_pulse_enemy.vpcf",
  },
  storm_magical = {
    extra_targets = 1,                        -- DR owner: max 2 different targets per cast
    chain_chance = { 0.20, 0.20, 0.20 },      -- [ult] DR owner 20% at rank 1; ranks 2-3 PD keep 20%
    chain_damage = { 300, 380, 460 },         -- [ult] DR owner 300 at rank 1; 380/460 PD
    second_target_radius = 600,               -- PD
    cast_context_seconds = 3,                 -- PD: max wait for both daggers
    -- fallbacks when the hidden native Stifling Dagger cannot be read (native copy, OP-004)
    dagger_cooldown = 6,
    dagger_mana = 30,
    dagger_range = { 700, 850, 1000, 1150 },  -- [q]
    dagger_speed = 1200,
    dagger_base_damage = { 65, 70, 75, 80 },  -- [q]
    dagger_attack_factor = { -70, -55, -40, -25 }, -- [q] percent of attack damage
    dagger_slow = -50,
    dagger_slow_duration = { 2.1, 2.4, 2.7, 3.0 }, -- [q]
    dagger_particle = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf",
    chain_particle = "particles/items_fx/chain_lightning.vpcf",  -- VERIFY (OP-021)
  },
}

return B
