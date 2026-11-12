local Scoring = require("rift.core.scoring")

local function setup(n)
  local cfg = T.config()
  local s = Scoring.new(cfg)
  for i = 0, (n or 4) - 1 do s:add_player(i) end
  return s, cfg
end

T.case("plain kill gives +3 and kill gold/xp", function()
  local s, cfg = setup()
  local r = s:on_hero_death(1, 0, 100, 1000, "a")
  T.eq(r.killer, 0)
  T.eq(r.kill_score, 3)
  T.eq(r.kill_gold, cfg.economy.kill_gold)
  T.eq(r.kill_xp, cfg.economy.kill_xp)
  T.eq(s:get(0).score, 3)
  T.eq(s:get(1).deaths, 1)
  T.eq(s:get(1).score, 0, "death does not remove score")
end)

T.case("duplicate death token ignored", function()
  local s = setup()
  T.ok(s:on_hero_death(1, 0, 100, 1000, "tok"))
  local r, why = s:on_hero_death(1, 0, 100, 1000, "tok")
  T.eq(r, nil)
  T.eq(why, "duplicate")
  T.eq(s:get(0).score, 3)
end)

T.case("assists: threshold 10%, max 2, top damage, killer excluded", function()
  local s = setup(5)
  s:record_damage(1, 2, 300, 95)   -- 30%
  s:record_damage(1, 3, 150, 96)   -- 15%
  s:record_damage(1, 4, 200, 97)   -- 20%
  s:record_damage(1, 0, 500, 98)   -- killer
  local r = s:on_hero_death(1, 0, 100, 1000, "x")
  T.eq(#r.assists, 2)
  T.eq(r.assists[1].pid, 2)
  T.eq(r.assists[2].pid, 4)
  T.eq(s:get(3).assists, 0)
  T.eq(s:get(2).score, 1)
end)

T.case("assist below threshold / outside window / self damage ignored", function()
  local s = setup()
  s:record_damage(1, 2, 99, 99)    -- 9.9%
  s:record_damage(1, 3, 500, 80)   -- older than 10 s at t=100 -> pruned/ignored
  s:record_damage(1, 1, 500, 99)   -- self
  s:record_damage(1, 2, 0, 99)     -- zero
  local r = s:on_hero_death(1, 0, 100, 1000, "x")
  T.eq(#r.assists, 0)
end)

T.case("suicide credited to last enemy within 10 s, no double reward", function()
  local s = setup()
  s:record_damage(1, 2, 50, 92)
  s:record_damage(1, 3, 50, 95)
  local r = s:on_hero_death(1, 1, 100, 1000, "x")
  T.eq(r.killer, 3)
  T.eq(r.reason, "environment_credit")
  T.eq(s:get(3).score, 3)
  T.eq(s:get(2).score, 0, "no assist: 5% < 10%")
  T.eq(s:get(3).assists, 0, "credited killer not also assister")
end)

T.case("environment death with no contribution gives nothing", function()
  local s = setup()
  local r = s:on_hero_death(1, nil, 100, 1000, "x")
  T.eq(r.killer, nil)
  T.eq(r.reason, "no_credit")
  for i = 0, 3 do T.eq(s:get(i).score, 0) end
  T.eq(s:get(1).deaths, 1)
end)

T.case("streak bonus +1 at 3, +2 at 5, capped at 5 total", function()
  local s = setup()
  local v = s:get(1)
  v.streak = 3
  T.eq(s:on_hero_death(1, 0, 100, 1000, "a").kill_score, 4)
  T.eq(v.streak, 0)
  v.streak = 7
  T.eq(s:on_hero_death(1, 2, 300, 1000, "b").kill_score, 5)
end)

T.case("anti-feed: same pair within window reduces score/gold/xp", function()
  local s, cfg = setup()
  local r1 = s:on_hero_death(1, 0, 100, 1000, "1")
  local r2 = s:on_hero_death(1, 0, 130, 1000, "2")
  local r3 = s:on_hero_death(1, 0, 160, 1000, "3")
  local r4 = s:on_hero_death(1, 0, 180, 1000, "4")
  T.eq(r1.kill_score, 3); T.eq(r2.kill_score, 1); T.eq(r3.kill_score, 0); T.eq(r4.kill_score, 0)
  T.eq(r2.kill_gold, math.floor(cfg.economy.kill_gold * 0.5))
  T.eq(r4.kill_gold, 0)
  T.eq(s:get(0).score, 4)
end)

T.case("anti-feed: window expiry restores normal reward; other pairs unaffected", function()
  local s = setup()
  s:on_hero_death(1, 0, 100, 1000, "1")
  T.eq(s:on_hero_death(2, 0, 110, 1000, "2").kill_score, 3, "different victim")
  T.eq(s:on_hero_death(1, 0, 100 + 91, 1000, "3").kill_score, 3, "after window")
end)

T.case("anti-feed disabled by dev flag", function()
  local s = setup()
  s.anti_feed_enabled = false
  s:on_hero_death(1, 0, 100, 1000, "1")
  T.eq(s:on_hero_death(1, 0, 101, 1000, "2").kill_score, 3)
end)

T.case("leaders and standings", function()
  local s = setup()
  s:add_score(2, 5, 10, "test")
  s:add_score(3, 5, 12, "test")
  local l, best = s:leaders()
  T.eq(#l, 2); T.eq(best, 5); T.eq(l[1], 2)
  T.eq(s:standings()[1].pid, 2)
end)
