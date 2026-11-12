-- Legion Commander magical direction: passive spell amp progression and the
-- archer statue (replaces the third ability). Pure logic.

local M = {}

-- Persistent per-owner state (survives death/reconnect; independent of modifiers).
function M.new_owner_state()
  return { earned = 0, credited = {} }
end

-- Credit a real enemy hero kill/assist exactly once per (victim, death token).
-- kind: "kill" | "assist"; multiplier: anti-feed multiplier from scoring (0..1).
function M.credit(state, cfg, kind, death_token, multiplier)
  if death_token ~= nil then
    if state.credited[death_token] then return 0 end
    state.credited[death_token] = true
  end
  local base = (kind == "kill") and cfg.per_kill or (kind == "assist" and cfg.per_assist or 0)
  local add = base * (multiplier or 1)
  state.earned = state.earned + add
  return add
end

-- min(cap[rank], base[rank] + earned); rank 0 -> 0; suspended (Break) -> 0.
function M.spell_amp(state, cfg, rank, suspended)
  if not rank or rank < 1 or suspended then return 0 end
  return math.min(cfg.cap_spell_amp[rank], cfg.base_spell_amp[rank] + state.earned)
end

---------------------------------------------------------------------------
-- Statue session
---------------------------------------------------------------------------
local Statue = {}
Statue.__index = Statue
M.Statue = Statue

local seq = 0

-- cfg = HeroBalance.lc.statue; level = ability rank 1..4
function Statue.new(cfg, level, now)
  seq = seq + 1
  local self = setmetatable({}, Statue)
  self.id, self.cfg, self.level = seq, cfg, level
  self.start = now
  self.next_shot = 1
  self.hits = {}         -- projectile id -> true (one CDR per projectile)
  self.total_cdr = 0
  self.alive = true
  return self
end

function Statue:expired(now) return now - self.start >= self.cfg.lifetime end
function Statue:arrow_damage() return self.cfg.arrow_damage[self.level] end
function Statue:health() return self.cfg.health[self.level] end

-- Returns list of shot indices due now. Missed slots (no target) are consumed by
-- the caller and never accumulate into a burst: only the latest due slot fires.
function Statue:due_shots(now)
  if not self.alive then return {} end
  local due = {}
  local times = self.cfg.shot_times
  while self.next_shot <= #times and now - self.start >= times[self.next_shot] do
    table.insert(due, self.next_shot)
    self.next_shot = self.next_shot + 1
  end
  if #due > 1 then due = { due[#due] } end
  return due
end

-- Arrow projectile hit. Returns cooldown reduction seconds to apply (0 if none).
function Statue:on_arrow_hit(projectile_id, target_is_real_enemy_hero)
  if self.hits[projectile_id] ~= nil then return 0 end
  self.hits[projectile_id] = true
  if not target_is_real_enemy_hero then return 0 end
  self.total_cdr = self.total_cdr + self.cfg.cdr_per_hit
  return self.cfg.cdr_per_hit
end

-- Single cooldown path: never negative.
function M.reduce_cooldown(remaining, amount)
  return math.max(0, (remaining or 0) - (amount or 0))
end

return M
