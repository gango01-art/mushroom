-- Match state machine. Pure logic: time is passed in, no engine calls.
-- States: BOOT -> SETUP -> HERO_SELECTION -> PREPARATION -> ACTIVE -> (OVERTIME) -> FINISHED
-- Transitions are one-way and idempotent: repeating an engine callback is a no-op.

local MatchState = {}
MatchState.__index = MatchState

MatchState.STATES = { "BOOT", "SETUP", "HERO_SELECTION", "PREPARATION", "ACTIVE", "OVERTIME", "FINISHED" }
local ORDER = {}
for i, s in ipairs(MatchState.STATES) do ORDER[s] = i end
MatchState.ORDER = ORDER

function MatchState.new(config)
  local self = setmetatable({}, MatchState)
  self.config = config
  self.state = "BOOT"
  self.listeners = {}
  self.active_start = nil   -- game time at ACTIVE start
  self.active_elapsed_at_end = nil
  self.overtime_start = nil
  self.result = nil
  return self
end

function MatchState:on(fn) table.insert(self.listeners, fn) end

-- Returns true if the transition happened.
function MatchState:advance(to, now)
  local cur = ORDER[self.state]
  local nxt = ORDER[to]
  assert(nxt, "unknown state " .. tostring(to))
  if nxt <= cur then return false end
  if self.state == "FINISHED" then return false end
  local from = self.state
  self.state = to
  if to == "ACTIVE" then self.active_start = now end
  if to == "OVERTIME" then self.overtime_start = now end
  for _, fn in ipairs(self.listeners) do fn(from, to, now) end
  return true
end

function MatchState:is(s) return self.state == s end

-- Rewards (score, economy, events) allowed?
function MatchState:rewards_open()
  return self.state == "ACTIVE" or self.state == "OVERTIME"
end

function MatchState:active_elapsed(now)
  if not self.active_start then return 0 end
  if self.active_elapsed_at_end then return self.active_elapsed_at_end end
  return math.max(0, now - self.active_start)
end

function MatchState:active_remaining(now)
  return math.max(0, self.config.match.active_seconds - self.active_elapsed(self, now))
end

function MatchState:overtime_remaining(now)
  if not self.overtime_start then return self.config.match.overtime_max_seconds end
  return math.max(0, self.config.match.overtime_max_seconds - (now - self.overtime_start))
end

-- Finish exactly once. result = { winner = pid, reason = "..." }
function MatchState:finish(result, now)
  if self.state == "FINISHED" then return false end
  self.active_elapsed_at_end = self:active_elapsed(now)
  self.result = result
  return self:advance("FINISHED", now)
end

return MatchState
