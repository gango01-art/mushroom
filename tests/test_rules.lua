local Rules = require("rift.core.rules")

T.case("respawn formula clamp(6 + floor(t/180), 6, 12)", function()
  local cfg = T.config()
  T.eq(Rules.respawn_seconds(cfg, 0), 6)
  T.eq(Rules.respawn_seconds(cfg, 179), 6)
  T.eq(Rules.respawn_seconds(cfg, 180), 7)
  T.eq(Rules.respawn_seconds(cfg, 1079), 11)
  T.eq(Rules.respawn_seconds(cfg, 5000), 12)
end)

T.case("passive income is time-based and keeps fractions", function()
  local cfg = T.config()
  local acc = Rules.new_accumulator()
  local g, x = 0, 0
  for _ = 1, 40 do
    local dg, dx = Rules.accumulate(acc, cfg, 0.25)
    g, x = g + dg, x + dx
  end
  T.eq(g, 100); T.eq(x, 180)
  local dg = Rules.accumulate(acc, cfg, 0)
  T.eq(dg, 0, "paused: no income")
end)

T.case("spawn picks farthest from enemies, penalizes recent, never nil", function()
  local cfg = T.config()
  local cands = { { name = "a", x = 0, y = 0 }, { name = "b", x = 2000, y = 0 }, { name = "c", x = 4000, y = 0 } }
  local enemies = { { x = 0, y = 0 } }
  local c, _, ideal = Rules.choose_spawn(cfg, cands, enemies, {}, 100)
  T.eq(c.name, "c"); T.ok(ideal)
  c = Rules.choose_spawn(cfg, cands, enemies, { c = 95 }, 100)
  T.eq(c.name, "c", "2000 margin beats 600 penalty")
  local close = { { name = "a", x = 0, y = 0 }, { name = "b", x = 100, y = 0 } }
  local c2, _, ideal2 = Rules.choose_spawn(cfg, close, enemies, {}, 0)
  T.eq(c2.name, "b"); T.ok(not ideal2)
end)
