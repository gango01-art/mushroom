-- Ties MatchState and Scoring together: end of regular time, overtime, tiebreaks.
-- Pure logic; call tick(now) from the engine thinker with server game time.

local MatchState = require("rift.core.match_state")

local Director = {}
Director.__index = Director

function Director.new(config, scoring)
  local self = setmetatable({}, Director)
  self.cfg = config
  self.scoring = scoring
  self.state = MatchState.new(config)
  self.contenders = nil
  scoring:on_score(function(pid, delta, now, source)
    self:_on_score(pid, delta, now, source)
  end)
  return self
end

function Director:_on_score(pid, delta, now, source)
  if not self.state:is("OVERTIME") or not self.contenders then return end
  if delta <= 0 or not self.contenders[pid] then return end
  -- First contender to score wins; finish() is idempotent so later events in the
  -- same tick are rejected.
  self.state:finish({ winner = pid, reason = "overtime_first_point" }, now)
end

-- Final tiebreak among a list of pids.
function Director:tiebreak(pids)
  local sc = self.scoring
  local list = {}
  for _, pid in ipairs(pids) do table.insert(list, sc:get(pid)) end
  table.sort(list, function(a, b)
    if a.kills ~= b.kills then return a.kills > b.kills end
    if a.deaths ~= b.deaths then return a.deaths < b.deaths end
    if a.last_score_time ~= b.last_score_time then return a.last_score_time < b.last_score_time end
    return a.order < b.order
  end)
  local w, r = list[1], list[2]
  local reason
  if not r then reason = "score"
  elseif w.kills ~= r.kills then reason = "tiebreak_kills"
  elseif w.deaths ~= r.deaths then reason = "tiebreak_deaths"
  elseif w.last_score_time ~= r.last_score_time then reason = "tiebreak_earlier_score"
  else reason = "tiebreak_player_order" end
  return w.pid, reason
end

function Director:tick(now)
  local st = self.state
  if st:is("ACTIVE") and st:active_remaining(now) <= 0 then
    local leaders = self.scoring:leaders()
    if #leaders == 0 then
      st:finish({ winner = nil, reason = "no_players" }, now)
    elseif #leaders == 1 then
      st:finish({ winner = leaders[1], reason = "score" }, now)
    else
      self.contenders = {}
      for _, pid in ipairs(leaders) do self.contenders[pid] = true end
      self.contender_list = leaders
      st:advance("OVERTIME", now)
    end
  elseif st:is("OVERTIME") and st:overtime_remaining(now) <= 0 then
    local pid, reason = self:tiebreak(self.contender_list)
    st:finish({ winner = pid, reason = reason }, now)
  end
end

return Director
