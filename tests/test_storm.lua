local Storm = require("rift.core.pa_storm_daggers")
local V = { chain_chance = 0.20, chain_damage = 300, cast_context_seconds = 3 }
local ALWAYS = { chain_chance = 1.0, chain_damage = 300, cast_context_seconds = 3 }
local NEVER = { chain_chance = 0.0, chain_damage = 300, cast_context_seconds = 3 }

T.case("two valid hits of one cast -> one chain, 300 per target", function()
  local s = Storm.new(1)
  local id = s:begin_cast(0, 101, 102, ALWAYS, 0)
  T.eq(s:on_hit(id, 101, true, 0.3), nil)
  local c = s:on_hit(id, 102, true, 0.4)
  T.ok(c); T.eq(c.damage, 300); T.eq(c.targets[1], 101); T.eq(c.targets[2], 102)
  T.eq(s:on_hit(id, 102, true, 0.5), nil, "no second chain")
  T.eq(s:count(), 0)
end)

T.case("one target -> no roll, no chain", function()
  local s = Storm.new(1)
  local id, proc = s:begin_cast(0, 101, nil, ALWAYS, 0)
  T.ok(not proc)
  T.eq(s:on_hit(id, 101, true, 0.2), nil)
end)

T.case("disjoint/invalid dagger -> no chain", function()
  local s = Storm.new(1)
  local id = s:begin_cast(0, 101, 102, ALWAYS, 0)
  s:on_hit(id, 101, false, 0.2)
  T.eq(s:on_hit(id, 102, true, 0.3), nil)
end)

T.case("no proc -> no chain; duplicate hit events ignored", function()
  local s = Storm.new(1)
  local id = s:begin_cast(0, 101, 102, NEVER, 0)
  s:on_hit(id, 101, true, 0.1); s:on_hit(id, 101, true, 0.1)
  T.eq(s:on_hit(id, 102, true, 0.2), nil)
end)

T.case("expired context gives nothing", function()
  local s = Storm.new(1)
  local id = s:begin_cast(0, 101, 102, ALWAYS, 0)
  s:on_hit(id, 101, true, 1)
  T.eq(s:on_hit(id, 102, true, 3.5), nil)
end)

T.case("overlapping casts never mix targets", function()
  local s = Storm.new(1)
  local a = s:begin_cast(0, 101, 102, ALWAYS, 0)
  local b = s:begin_cast(0, 103, 104, ALWAYS, 0.1)
  T.eq(s:on_hit(a, 103, true, 0.2), nil, "foreign target ignored")
  s:on_hit(a, 101, true, 0.2)
  s:on_hit(b, 103, true, 0.25)
  local cb = s:on_hit(b, 104, true, 0.3)
  local ca = s:on_hit(a, 102, true, 0.35)
  T.eq(ca.targets[2], 102); T.eq(cb.targets[1], 103)
end)

T.case("same primary and secondary is treated as one target", function()
  local s = Storm.new(1)
  local id, proc = s:begin_cast(0, 101, 101, ALWAYS, 0)
  T.ok(not proc)
  T.eq(s:on_hit(id, 101, true, 0.1), nil)
end)

T.case("one roll per cast: proc rate ~20% over 20000 casts", function()
  local s = Storm.new(77)
  local procs = 0
  for i = 1, 20000 do
    local id, proc = s:begin_cast(0, 1, 2, V, i)
    if proc then procs = procs + 1 end
    s:on_hit(id, 1, true, i); s:on_hit(id, 2, true, i)
  end
  local rate = procs / 20000
  T.ok(rate > 0.18 and rate < 0.22, "rate " .. rate)
end)

T.case("context budget per caster", function()
  local s = Storm.new(1)
  for i = 1, 10 do s:begin_cast(0, 1, 2, V, 0) end
  T.eq(s:count(), Storm.MAX_CONTEXTS_PER_CASTER)
end)

T.case("secondary target: hero first, then nearest unit, within radius", function()
  local p = { x = 0, y = 0 }
  local c = {
    { id = 5, x = 100, y = 0, is_hero = false },
    { id = 6, x = 500, y = 0, is_hero = true },
    { id = 7, x = 900, y = 0, is_hero = true },
  }
  T.eq(Storm.pick_secondary(1, p, c, 600), 6)
  T.eq(Storm.pick_secondary(6, p, c, 600), 5)
  T.eq(Storm.pick_secondary(1, p, { { id = 1, x = 0, y = 0, is_hero = true } }, 600), nil)
  T.eq(Storm.pick_secondary(1, p, { { id = 8, x = 300, y = 0 }, { id = 9, x = 200, y = 0 } }, 600), 9)
end)
