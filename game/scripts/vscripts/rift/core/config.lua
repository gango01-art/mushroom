-- RIFT ARENA: single source of balance and rules numbers.
-- Pure data. No engine globals here. Everything tunable lives in this file.
-- Values marked HYPOTHESIS are starting balance guesses from the brief.

local Config = {}

Config.VERSION = "0.3.0-lab"
Config.SCHEMA_VERSION = 1

Config.match = {
  max_players = 8,
  min_players_dev = 1,          -- single player allowed only with dev = true
  hero_selection_seconds = 40,
  preparation_seconds = 10,
  active_seconds = 30 * 60,
  overtime_max_seconds = 120,
  setup_autolaunch_seconds = 5, -- custom game setup screen delay
}

Config.score = {
  kill = 3,
  assist = 1,
  max_assisters = 2,
  max_kill_reward = 5,          -- cap of kill + streak bonus (before anti-feed)
  assist_window_seconds = 10,
  assist_min_damage_fraction = 0.10, -- of victim max HP at death
  env_kill_window_seconds = 10, -- suicide/environment credit window
  streak_bonus = {              -- by victim streak (kills without death)
    { min = 5, bonus = 2 },
    { min = 3, bonus = 1 },
  },
}

-- Anti-feed: repeated kills of the SAME victim by the SAME killer inside the window.
-- index = repeat number inside window (1 = first kill, normal). Multiplier applies to
-- score, gold and XP of the killer; score is floored. Assists are unaffected.
Config.anti_feed = {
  enabled = true,
  window_seconds = 90,
  multipliers = { 1.0, 0.5, 0.25, 0.0 }, -- 4th+ repeat gives nothing
}

Config.economy = {
  start_level = 3,
  start_gold = 600,
  passive_gold_per_second = 4,
  passive_gold_phases = {
    {until_seconds=240,rate=4}, {until_seconds=600,rate=8},
    {until_seconds=1200,rate=10}, {until_seconds=1e9,rate=14},
  }, -- initial economy for 30-minute playtests
  passive_xp_per_second = 14,    -- Slower early levels; combat/camps remain additional sources.
  kill_gold = 150,
  kill_xp = 120,
  assist_gold = 50,
  assist_xp = 40,
  buyback_enabled = false,
  lose_gold_on_death = false,
  catch_up = { enabled = false, level_gap = 2, max_xp_bonus = 0.20 },
}

Config.respawn = {
  base_seconds = 6,
  step_seconds = 180,            -- +1 s per 180 s of ACTIVE
  min_seconds = 6,
  max_seconds = 12,
  shield_seconds = 2,
  desired_enemy_distance = 900,
  recent_use_seconds = 20,
  recent_use_penalty = 600,      -- units subtracted from score for recent use
}

-- Protected home bases on the authored arena. Standard-map lab has no bases.
Config.sanctuary = {
  teams={2,3,6,7,8,9,10,11}, radius=450, hp_regen_pct=20, mana_regen_pct=20,
  purge_interval=.2, tower_range=550, tower_damage=120, tower_attack_rate=1,
  knockback_distance=500, knockback_duration=.35, knockback_height=45,
  tower_unit="npc_rift_base_guardian",
  tower_model="models/props_structures/tower_good.vmdl", tower_scale=.85,
  tower_health=10000,tower_armor=25,tower_magic_resistance=80,tower_vision=1100,
  guardian_buffer=100, guardian_think=.2,
}

-- 12 regular upgrade offers, seconds of ACTIVE.
Config.upgrades = {
  schedule = { 30, 120, 240, 360, 480, 600, 780, 960, 1140, 1320, 1500, 1680 },
  offer_seconds = 45,             -- applies to regular and ultimate direction offers
  options_per_offer = 3,
  exhaust_compensation_gold = 300, -- HYPOTHESIS: when no valid option exists (bounded by schedule)
  rarity_phases = {              -- upper bound of phase in ACTIVE seconds
    { until_seconds = 360,  weights = { common = 70, rare = 25, epic = 5 } },
    { until_seconds = 720,  weights = { common = 50, rare = 35, epic = 15 } },
    { until_seconds = 1e9,  weights = { common = 35, rare = 40, epic = 25 } },
  },
}

Config.relic = {
  schedule = { 180, 420, 660, 900, 1140, 1380, 1620 },
  warning_seconds = 15,
  duration_seconds = 75,
  score_interval_seconds = 12,
  score_budget = 4,
  pickup_radius = 150,           -- HYPOTHESIS
  reveal_interval = 1.0,         -- carrier position revealed to everyone this often
  reveal_radius = 350,
  carrier_move_slow_pct = 0,     -- separate tunable; 0 until tested
  -- Particle paths: VERIFY in Asset Browser (OP-008). Missing paths only lose visuals.
  model_ground="models/props_gameplay/rune_arcane.vmdl",model_scale=.8,
  particle_ground = "particles/generic_gameplay/rune_arcane.vpcf",
  particle_carrier = "particles/generic_gameplay/rune_arcane_owner.vpcf",
  ground_vision=250,
}

Config.dev = {
  -- Overridden at runtime by engine layer (IsInToolsMode / cheats). Never trust client.
  enabled = false,
  disable_anti_feed = false,
}

-- Single-player Tools/cheats laboratory. Never enabled in a normal PvP lobby.
Config.lab = {
  hero_level = 25, gold = 25000, request_interval = 0.3,
  precache_timeout_seconds = 30,
  gallery_radius = 1300, target_distance = 450,
  target_health = 10000, mortal_health = 2500, max_targets = 6, respawn_seconds = 2,
  nav_step = 128, nav_search_steps = 8, placement_separation = 150,
}

-- One shared pool, never multiplied by the number of heroes in the circle.
Config.center_gold = {
 radius=900, public_vision=true, vision_margin=96, vision_duration=.6, phases={{until_seconds=600,rate=2},{until_seconds=1200,rate=3},{until_seconds=1e9,rate=4}},
 splash_particle="particles/generic_gameplay/water_splash.vpcf",
}

Config.river_camps={
 first_spawn=90,respawn_seconds=90,leash=600,aggro=450,think=.3,heal_pct=5,
 phases={{until_seconds=600,scale=1},{until_seconds=1200,scale=1.5},{until_seconds=1e9,scale=2}},
 members={
  {unit="npc_rift_river_frog",model="models/creeps/neutral_creeps/n_creep_froglet/n_creep_froglet.vmdl",size=1,health=280,damage=10,armor=1,gold=30,xp=15,dx=-110,dy=0},
  {unit="npc_rift_river_mage",model="models/creeps/neutral_creeps/n_creep_froglet/n_creep_froglet_mage.vmdl",size=1,health=280,damage=12,armor=1,gold=30,xp=15,dx=110,dy=0,ranged=true},
  {unit="npc_rift_river_guard",model="models/creeps/neutral_creeps/n_creep_ancient_frog/n_creep_ancient_frog.vmdl",size=1,health=560,damage=22,armor=3,gold=60,xp=30,dx=0,dy=140},
 },
}

Config.roshan={
 unit="npc_rift_roshan",model="models/creeps/roshan/roshan.vmdl",rotate_seconds=300,respawn_seconds=300,
 health=7000,damage=80,armor=12,magic_resistance=35,regen=12,
 move_speed=270,attack_rate=2,aggro=600,leash=1000,think=.3,
 throw_ability="roshan_grab_and_throw",max_throws_per_trip=5,
 abilities={"roshan_revengeroar","roshan_slam","roshan_inherent_buffs","roshan_devotion","roshan_bash","roshan_spell_block","roshan_grab_and_throw"},
 slam_ability="roshan_slam",roar_ability="roshan_revengeroar",roar_health_fraction=.75,
 gold=500,
 reveal_radius=350,reveal_duration=.6,
 phases={{until_seconds=600,scale=1},{until_seconds=1200,scale=1.35},{until_seconds=1e9,scale=1.7}},
 spawn_particle="particles/neutral_fx/roshan_spawn.vpcf",slam_particle="particles/neutral_fx/roshan_slam.vpcf",
 torch_particle="particles/props/roshan_torch_flame_a.vpcf",
}

return Config
