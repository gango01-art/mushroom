-- RIFT ARENA: single source of balance and rules numbers.
-- Pure data. No engine globals here. Everything tunable lives in this file.
-- Values marked HYPOTHESIS are starting balance guesses from the brief.

local Config = {}

Config.VERSION = "0.1.0-a"
Config.SCHEMA_VERSION = 1

Config.match = {
  max_players = 8,
  min_players_dev = 1,          -- single player allowed only with dev = true
  hero_selection_seconds = 40,
  preparation_seconds = 10,
  active_seconds = 18 * 60,
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
  start_gold = 1200,
  passive_gold_per_second = 10,  -- HYPOTHESIS
  passive_xp_per_second = 18,    -- HYPOTHESIS
  kill_gold = 180,
  kill_xp = 120,
  assist_gold = 60,
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

-- 12 regular upgrade offers, seconds of ACTIVE.
Config.upgrades = {
  schedule = { 30, 120, 210, 300, 390, 480, 570, 660, 750, 840, 930, 1020 },
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
  schedule = { 180, 360, 540, 720, 900 },
  warning_seconds = 15,
  duration_seconds = 75,
  score_interval_seconds = 12,
  score_budget = 4,
}

Config.dev = {
  -- Overridden at runtime by engine layer (IsInToolsMode / cheats). Never trust client.
  enabled = false,
  disable_anti_feed = false,
}

return Config
