-- "Heart of the Rift" relic event. Pure logic; the engine supplies positions,
-- validity and time. One relic at most; schedule in ACTIVE seconds.
-- Rules (docs/BRIEF.md section 15):
--  * warning 15 s before spawn with the chosen point; event lasts <= 75 s from spawn
--  * carrier gets +1 per 12 FULL seconds of continuous holding; <= 4 per event total
--  * budget and event clock never reset on transfer; partial interval resets on transfer
--  * pickup gives nothing; drop on carrier death; reset on disconnect/invalid area
--  * overtime/finished: everything cleared, no awards after the event ends

local Rng = require("rift.core.rng")

local Relic = {}
Relic.__index = Relic

-- point_count: number of relic points on the map (>= 1)
function Relic.new(cfg, seed, point_count)
  local self = setmetatable({}, Relic)
  self.cfg = cfg
  self.rng = Rng.derive(seed or 1, "relic")
  self.point_count = math.max(1, point_count or 1)
  self.index = 1              -- next scheduled event
  self.state = "idle"         -- idle | warned | ground | carried
  self.event = nil
  self.cancelled = false
  return self
end

local function new_event(self, idx)
  return { index = idx, point = self.rng:int(self.point_count), spawn_at = self.cfg.schedule[idx],
           spawned_time = nil, carrier = nil, hold_start = nil, awarded = 0, by_player = {} }
end

-- Returns list of events for the engine:
--  { kind = "warning", point, spawn_in } | { kind = "spawn", point } | { kind = "score", pid, points }
--  { kind = "ended", reason, by_player } | { kind = "cleared" }
-- allowed = false (overtime/finished) clears the event and blocks new ones.
function Relic:tick(now, active_elapsed, allowed)
  local out = {}
  if self.cancelled then return out end   -- overtime/finished never returns to ACTIVE
  if not allowed then
    if not self.cancelled then
      self.cancelled = true
      if self.state ~= "idle" then table.insert(out, { kind = "cleared" }) end
      self.state, self.event = "idle", nil
    end
    return out
  end
  local sched = self.cfg.schedule
  -- skip schedule entries fully in the past (dev clock jumps)
  while self.state == "idle" and self.index <= #sched
        and active_elapsed >= sched[self.index] + self.cfg.duration_seconds do
    self.index = self.index + 1
  end
  if self.state == "idle" and self.index <= #sched
     and active_elapsed >= sched[self.index] - self.cfg.warning_seconds then
    self.event = new_event(self, self.index)
    self.index = self.index + 1
    self.state = "warned"
    table.insert(out, { kind = "warning", point = self.event.point,
                        spawn_in = math.max(0, self.event.spawn_at - active_elapsed) })
  end
  local e = self.event
  if self.state == "warned" and active_elapsed >= e.spawn_at then
    self.state = "ground"
    e.spawned_time = now
    table.insert(out, { kind = "spawn", point = e.point })
  end
  if self.state == "carried" then self:_award(now, out) end
  if (self.state == "ground" or self.state == "carried") then
    if e.awarded >= self.cfg.score_budget then
      self:_end("budget", out)
    elseif now - e.spawned_time >= self.cfg.duration_seconds then
      self:_end("timeout", out)
    end
  end
  return out
end

function Relic:_award(now, out)
  local e = self.event
  local interval = self.cfg.score_interval_seconds
  while e.awarded < self.cfg.score_budget and now - e.hold_start >= interval do
    e.hold_start = e.hold_start + interval
    e.awarded = e.awarded + 1
    e.by_player[e.carrier] = (e.by_player[e.carrier] or 0) + 1
    table.insert(out, { kind = "score", pid = e.carrier, points = 1 })
  end
end

function Relic:_end(reason, out)
  local e = self.event
  table.insert(out, { kind = "ended", reason = reason, by_player = e.by_player })
  self.state, self.event = "idle", nil
end

-- Atomic pickup: only from the ground during an active event. Returns true/false.
function Relic:pickup(pid, now)
  if self.state ~= "ground" or pid == nil then return false end
  self.state = "carried"
  self.event.carrier = pid
  self.event.hold_start = now     -- partial interval starts fresh
  return true
end

-- Carrier died / disconnected / left the valid area: relic goes to the ground.
-- Award full intervals held up to now first; the partial interval is discarded.
function Relic:drop(now, out)
  if self.state ~= "carried" then return false end
  out = out or {}
  self:_award(now, out)
  self.state = "ground"
  self.event.carrier = nil
  self.event.hold_start = nil
  return true, out
end

-- Dev only: spawn an extra event now (does not consume the schedule).
function Relic:dev_spawn(now)
  if self.cancelled or self.state ~= "idle" then return nil end
  local e = new_event(self, 0)
  e.spawned_time = now
  self.event = e
  self.state = "ground"
  return { { kind = "spawn", point = e.point } }
end

-- Dev only: end the current event now.
function Relic:dev_end()
  if self.state == "idle" then return {} end
  local out = {}
  self:_end("dev", out)
  return out
end

function Relic:carrier() return self.event and self.event.carrier or nil end

function Relic:view(now, active_elapsed)
  local e = self.event
  local v = { state = self.state, carrier = -1, point = -1, remaining = 0, budget_left = 0, next_point_in = 0,
              next_event_in = -1 }
  if e then
    v.point = e.point
    v.carrier = e.carrier or -1
    v.budget_left = self.cfg.score_budget - e.awarded
    if e.spawned_time then v.remaining = math.max(0, self.cfg.duration_seconds - (now - e.spawned_time)) end
    if e.hold_start then v.next_point_in = math.max(0, self.cfg.score_interval_seconds - (now - e.hold_start)) end
    if self.state == "warned" then v.next_event_in = math.max(0, e.spawn_at - active_elapsed) end
  elseif not self.cancelled and self.index <= #self.cfg.schedule then
    v.next_event_in = math.max(0, self.cfg.schedule[self.index] - active_elapsed)
  end
  return v
end

return Relic
