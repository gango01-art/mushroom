local Scoring = require("rift.core.scoring")
local Director = require("rift.core.match_director")

local function setup()
  local cfg = T.config()
  local s = Scoring.new(cfg)
  for i = 0, 3 do s:add_player(i) end
  local d = Director.new(cfg, s)
  d.state:advance("ACTIVE", 0)
  return d, s, cfg
end

T.case("single leader wins at 18:00", function()
  local d, s, cfg = setup()
  s:add_score(2, 4, 10, "t")
  d:tick(cfg.match.active_seconds - 1)
  T.ok(d.state:is("ACTIVE"))
  d:tick(cfg.match.active_seconds)
  T.ok(d.state:is("FINISHED"))
  T.eq(d.state.result.winner, 2)
  T.eq(d.state.result.reason, "score")
end)

T.case("tie -> overtime; first contender to score wins; others cannot", function()
  local d, s, cfg = setup()
  s:add_score(1, 3, 10, "t"); s:add_score(2, 3, 11, "t")
  local T0 = cfg.match.active_seconds
  d:tick(T0)
  T.ok(d.state:is("OVERTIME"))
  s:add_score(3, 3, T0 + 5, "t")    -- non-contender: no win
  T.ok(d.state:is("OVERTIME"))
  s:add_score(2, 1, T0 + 6, "t")    -- contender
  s:add_score(1, 1, T0 + 6, "t")    -- same tick, later: rejected
  T.ok(d.state:is("FINISHED"))
  T.eq(d.state.result.winner, 2)
  T.eq(d.state.result.reason, "overtime_first_point")
end)

T.case("overtime timeout: kills, then deaths, then earlier score, then order", function()
  local d, s, cfg = setup()
  s:add_score(1, 3, 20, "t"); s:add_score(2, 3, 10, "t")
  local T0 = cfg.match.active_seconds
  d:tick(T0)
  d:tick(T0 + cfg.match.overtime_max_seconds)
  T.ok(d.state:is("FINISHED"))
  T.eq(d.state.result.winner, 2)
  T.eq(d.state.result.reason, "tiebreak_earlier_score")
end)

T.case("tiebreak by kills and deaths", function()
  local d, s = setup()
  s:get(1).kills = 2; s:get(2).kills = 1
  local w, r = d:tiebreak({ 1, 2 })
  T.eq(w, 1); T.eq(r, "tiebreak_kills")
  s:get(2).kills = 2; s:get(2).deaths = 0; s:get(1).deaths = 1
  w, r = d:tiebreak({ 1, 2 })
  T.eq(w, 2); T.eq(r, "tiebreak_deaths")
  s:get(1).deaths = 0
  w, r = d:tiebreak({ 2, 1 })
  T.eq(w, 1); T.eq(r, "tiebreak_player_order")
end)

T.case("overtime is bounded", function()
  local d, s, cfg = setup()
  local T0 = cfg.match.active_seconds
  d:tick(T0) -- all zero -> 4-way tie
  T.ok(d.state:is("OVERTIME"))
  d:tick(T0 + 1000)
  T.ok(d.state:is("FINISHED"))
end)
