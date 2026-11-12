-- Scoring, assists, streaks, anti-feed, environment-kill attribution.
-- Pure logic. Player ids are numbers (Dota PlayerID). Time is game time in seconds.
-- The engine layer is responsible for: resolving summons/illusions to the owning
-- player, ignoring non-real-hero deaths, reincarnation, and calling on_hero_death
-- once per confirmed death (a death token guard is also kept here).

local Scoring = {}
Scoring.__index = Scoring

function Scoring.new(config)
  local self = setmetatable({}, Scoring)
  self.cfg = config
  self.players = {}     -- pid -> record
  self.order = {}       -- stable order of registration (technical tiebreak)
  self.damage = {}      -- victim pid -> list of { attacker, amount, t }
  self.pair_kills = {}  -- "killer:victim" -> list of times (survives reconnects)
  self.listeners = {}
  self.anti_feed_enabled = config.anti_feed.enabled
  return self
end

function Scoring:on_score(fn) table.insert(self.listeners, fn) end

function Scoring:add_player(pid)
  if self.players[pid] then return self.players[pid] end
  local rec = {
    pid = pid, score = 0, kills = 0, deaths = 0, assists = 0,
    streak = 0, life = 1, last_score_time = 0, order = #self.order + 1,
    last_death_token = nil,
  }
  self.players[pid] = rec
  table.insert(self.order, pid)
  return rec
end

function Scoring:get(pid) return self.players[pid] end

local function emit(self, pid, delta, now, source)
  for _, fn in ipairs(self.listeners) do fn(pid, delta, now, source) end
end

-- Generic score grant (kills, assists, relic). Returns applied delta.
function Scoring:add_score(pid, delta, now, source)
  local rec = self.players[pid]
  if not rec or delta <= 0 then return 0 end
  rec.score = rec.score + delta
  rec.last_score_time = now
  emit(self, pid, delta, now, source)
  return delta
end

-- Post-mitigation damage from attacker player to victim player.
function Scoring:record_damage(victim, attacker, amount, now)
  if attacker == nil or victim == attacker then return end
  if not self.players[victim] or not self.players[attacker] then return end
  if not amount or amount <= 0 then return end
  local log = self.damage[victim]
  if not log then log = {}; self.damage[victim] = log end
  table.insert(log, { attacker = attacker, amount = amount, t = now })
  -- prune entries older than the largest window
  local keep = math.max(self.cfg.score.assist_window_seconds, self.cfg.score.env_kill_window_seconds)
  local cut = 0
  for i = 1, #log do
    if now - log[i].t > keep then cut = i else break end
  end
  if cut > 0 then
    for _ = 1, cut do table.remove(log, 1) end
  end
end

local function damage_by_attacker(log, now, window)
  local sums, last = {}, {}
  for _, e in ipairs(log or {}) do
    if now - e.t <= window then
      sums[e.attacker] = (sums[e.attacker] or 0) + e.amount
      if not last[e.attacker] or e.t >= last[e.attacker] then last[e.attacker] = e.t end
    end
  end
  return sums, last
end

function Scoring:streak_bonus(victim_streak)
  for _, s in ipairs(self.cfg.score.streak_bonus) do
    if victim_streak >= s.min then return s.bonus end
  end
  return 0
end

-- Counts this kill in pair history and returns (repeat_number, multiplier).
function Scoring:anti_feed(killer, victim, now)
  local key = killer .. ":" .. victim
  local list = self.pair_kills[key] or {}
  local fresh = {}
  for _, t in ipairs(list) do
    if now - t <= self.cfg.anti_feed.window_seconds then table.insert(fresh, t) end
  end
  table.insert(fresh, now)
  self.pair_kills[key] = fresh
  local n = #fresh
  if not self.anti_feed_enabled then return n, 1.0 end
  local m = self.cfg.anti_feed.multipliers
  return n, m[math.min(n, #m)]
end

-- Main entry. killer may be nil (environment/neutral) or == victim (suicide).
-- death_token: any unique value per engine death (e.g. game time + entindex) for dedupe.
-- Returns a result table, or nil + reason when ignored.
function Scoring:on_hero_death(victim, killer, now, victim_max_hp, death_token)
  local v = self.players[victim]
  if not v then return nil, "unknown_victim" end
  if death_token ~= nil and v.last_death_token == death_token then return nil, "duplicate" end
  v.last_death_token = death_token

  local sc = self.cfg.score
  local log = self.damage[victim]
  local result = { victim = victim, killer = nil, reason = "kill", assists = {} }

  -- Resolve credited killer
  if killer == nil or killer == victim or not self.players[killer] then
    local _, last = damage_by_attacker(log, now, sc.env_kill_window_seconds)
    local best, best_t = nil, -1
    for pid, t in pairs(last) do
      if t > best_t or (t == best_t and self.players[pid].order < self.players[best].order) then
        best, best_t = pid, t
      end
    end
    killer = best
    result.reason = killer and "environment_credit" or "no_credit"
  end

  -- Death statistics
  local victim_streak = v.streak
  v.deaths = v.deaths + 1
  v.streak = 0
  v.life = v.life + 1

  if killer then
    local k = self.players[killer]
    result.killer = killer
    local bonus = self:streak_bonus(victim_streak)
    local base = math.min(sc.kill + bonus, sc.max_kill_reward)
    local n, mult = self:anti_feed(killer, victim, now)
    result.repeat_n, result.multiplier, result.streak_bonus = n, mult, bonus
    result.kill_score = math.floor(base * mult)
    result.kill_gold = math.floor(self.cfg.economy.kill_gold * mult)
    result.kill_xp = math.floor(self.cfg.economy.kill_xp * mult)
    k.kills = k.kills + 1
    k.streak = k.streak + 1
    -- Assists first computed, then applied killer-first for deterministic order
    local sums = damage_by_attacker(log, now, sc.assist_window_seconds)
    local threshold = (victim_max_hp or 0) * sc.assist_min_damage_fraction
    local cands = {}
    for pid, dmg in pairs(sums) do
      if pid ~= killer and pid ~= victim and dmg >= threshold and dmg > 0 then
        table.insert(cands, { pid = pid, dmg = dmg })
      end
    end
    local players = self.players
    table.sort(cands, function(a, b)
      if a.dmg ~= b.dmg then return a.dmg > b.dmg end
      return players[a.pid].order < players[b.pid].order
    end)
    self:add_score(killer, result.kill_score, now, "kill")
    for i = 1, math.min(sc.max_assisters, #cands) do
      local a = players[cands[i].pid]
      a.assists = a.assists + 1
      local entry = { pid = a.pid, damage = cands[i].dmg, score = sc.assist,
                      gold = self.cfg.economy.assist_gold, xp = self.cfg.economy.assist_xp }
      table.insert(result.assists, entry)
      self:add_score(a.pid, entry.score, now, "assist")
    end
  end

  self.damage[victim] = nil
  return result
end

-- Snapshot rows for UI, sorted by score desc then stable order.
function Scoring:standings()
  local rows = {}
  for _, pid in ipairs(self.order) do table.insert(rows, self.players[pid]) end
  table.sort(rows, function(a, b)
    if a.score ~= b.score then return a.score > b.score end
    return a.order < b.order
  end)
  return rows
end

function Scoring:leaders()
  local best, out = -1, {}
  for _, pid in ipairs(self.order) do
    local s = self.players[pid].score
    if s > best then best, out = s, { pid } elseif s == best then table.insert(out, pid) end
  end
  return out, best
end

return Scoring
