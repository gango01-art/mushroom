-- Legion Commander physical "Duel": champion session rewards and outcomes.
-- Pure logic. The engine owns throne/champion entities and calls in with game time.
-- Permanent damage is fractional and never rounded per tick.

local Duel = {}
Duel.__index = Duel

Duel.REASONS = { victory = true, champion_death = true, timeout = true, leash_break = true,
                 owner_disconnect = true, owner_removed = true, match_finished = true,
                 target_lost = true } -- target died without a qualifying champion victory

-- Per-owner persistent state (lives in player state, survives death/reconnect).
function Duel.new_owner_state()
  return { earned = 0, pair_history = {} }
end

-- Anti-feed for permanent rewards: duels on the same target inside window.
function Duel.pair_multiplier(owner_state, target_key, now, anti_feed_cfg, enabled)
  local list = owner_state.pair_history[target_key] or {}
  local fresh = {}
  for _, t in ipairs(list) do
    if now - t <= anti_feed_cfg.window_seconds then table.insert(fresh, t) end
  end
  table.insert(fresh, now)
  owner_state.pair_history[target_key] = fresh
  if enabled == false then return 1.0 end
  local m = anti_feed_cfg.multipliers
  return m[math.min(#fresh, #m)]
end

-- cfg = HeroBalance.lc.duel_physical; rank = ultimate rank 1..3
function Duel.start(cfg, rank, owner_state, target_key, now, multiplier)
  local self = setmetatable({}, Duel)
  self.cfg, self.rank, self.owner = cfg, rank, owner_state
  self.target = target_key
  self.start_time = now
  self.multiplier = multiplier or 1.0
  self.paid = 0                -- permanent damage paid this session (after multiplier)
  self.payouts = 0
  self.last_hit = nil          -- last champion hit on the target (game time)
  self.champion_damage = 0     -- to target this session
  self.out_of_leash_since = nil
  self.ended, self.reason = false, nil
  return self
end

function Duel:per_second() return self.cfg.per_second[self.rank] end
function Duel:full_total() return self:per_second() * self.cfg.max_payouts end
function Duel:victory_total() return self:full_total() * self.cfg.victory_multiplier end

-- Grant up to amount respecting the per-direction cap. Returns granted amount.
function Duel:_grant(amount)
  local cap = self.cfg.permanent_cap[self.rank]
  local room = math.max(0, cap - self.owner.earned)
  local g = math.min(amount, room)
  if g <= 0 then return 0 end
  self.owner.earned = self.owner.earned + g
  self.paid = self.paid + g
  return g
end

function Duel:record_champion_hit(now, damage)
  if self.ended then return end
  self.last_hit = now
  self.champion_damage = self.champion_damage + math.max(0, damage or 0)
end

-- Ends exactly once. Returns result table.
function Duel:_finish(reason, extra)
  if self.ended then return nil end
  assert(Duel.REASONS[reason], "bad reason " .. tostring(reason))
  self.ended, self.reason = true, reason
  local r = { ended = true, reason = reason, payout = 0, penalty = nil }
  for k, v in pairs(extra or {}) do r[k] = v end
  if reason == "champion_death" then
    r.penalty = { max_hp_fraction = self.cfg.champion_death_penalty_fraction,
                  stun = self.cfg.champion_death_stun }
  end
  r.session_paid = self.paid
  return r
end

-- Call every thinker step. target_distance: target distance to throne (nil if unknown).
-- Returns { payout = x } per step and a result when the session ends.
function Duel:tick(now, target_distance)
  if self.ended then return nil end
  local elapsed = now - self.start_time
  local out = { payout = 0 }
  -- payouts at whole seconds 1..max_payouts, each needs a recent champion hit
  local due = math.min(self.cfg.max_payouts, math.floor(elapsed))
  while self.payouts < due do
    self.payouts = self.payouts + 1
    local t = self.start_time + self.payouts
    if self.last_hit and self.last_hit >= t - self.cfg.hit_window and self.last_hit <= t then
      out.payout = out.payout + self:_grant(self:per_second() * self.multiplier)
    end
  end
  -- leash
  if target_distance and target_distance > self.cfg.leash_distance then
    self.out_of_leash_since = self.out_of_leash_since or now
    if now - self.out_of_leash_since > self.cfg.leash_grace then
      local r = self:_finish("leash_break")
      r.payout = out.payout
      return r
    end
  else
    self.out_of_leash_since = nil
  end
  if elapsed >= self.cfg.max_seconds then
    local r = self:_finish("timeout")
    r.payout = out.payout
    return r
  end
  return out
end

-- Simultaneous resolution of deaths in one server tick (engine collects flags).
-- Priority: champion_death beats victory (no victory reward).
function Duel:resolve_deaths(champion_dead, target_dead, target_max_hp)
  if self.ended then return nil end
  if champion_dead then return self:_finish("champion_death") end
  if target_dead then
    local need = (target_max_hp or 0) * self.cfg.victory_min_damage_fraction
    if self.champion_damage >= need and self.champion_damage > 0 then
      local top = math.max(0, self:victory_total() * self.multiplier - self.paid)
      local g = self:_grant(top)
      return self:_finish("victory", { payout = g })
    end
    -- target died to someone else / insufficient champion contribution: ends without victory
    return self:_finish("target_lost")
  end
  return nil
end

function Duel:abort(reason)
  return self:_finish(reason)
end

return Duel
