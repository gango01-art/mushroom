local Relic = require("rift.core.relic_event")

-- Active time == game time offset by 1000 in these tests.
local function setup()
  local cfg = T.config()
  return Relic.new(cfg.relic, 7, 4), cfg.relic
end
local function kinds(ev)
  local t = {}
  for _, e in ipairs(ev) do t[#t + 1] = e.kind end
  return table.concat(t, ",")
end
local function run(r, from, to, step, allowed)
  local all = {}
  local t = from
  while t <= to + 1e-9 do
    for _, e in ipairs(r:tick(1000 + t, t, allowed ~= false)) do all[#all + 1] = e end
    t = t + step
  end
  return all
end

T.case("warning 15 s before 3:00, spawn at 3:00 with a valid point", function()
  local r = setup()
  T.eq(kinds(r:tick(1000 + 164, 164, true)), "")
  local w = r:tick(1000 + 165, 165, true)
  T.eq(w[1].kind, "warning"); T.ok(w[1].point >= 1 and w[1].point <= 4); T.eq(w[1].spawn_in, 15)
  local s = r:tick(1000 + 180, 180, true)
  T.eq(s[1].kind, "spawn"); T.eq(s[1].point, w[1].point)
end)

T.case("pickup gives nothing; +1 per 12 full seconds; budget 4", function()
  local r = setup()
  run(r, 165, 180, 1)
  T.ok(r:pickup(2, 1180))
  T.ok(not r:pickup(3, 1180), "atomic: second pickup refused")
  local ev = run(r, 181, 240, 0.5)
  local pts = 0
  for _, e in ipairs(ev) do if e.kind == "score" then pts = pts + e.points; T.eq(e.pid, 2) end end
  T.eq(pts, 4)
  T.eq(ev[#ev].kind, "ended"); T.eq(ev[#ev].reason, "budget")
end)

T.case("transfer resets partial interval but not budget or event clock", function()
  local r = setup()
  run(r, 165, 180, 1)
  r:pickup(1, 1180)
  run(r, 181, 191, 1)            -- 11 s held: no point yet
  r:drop(1191)
  r:pickup(2, 1192)
  local ev = run(r, 193, 203, 1)  -- 11 s: no point
  for _, e in ipairs(ev) do T.ok(e.kind ~= "score", "partial discarded") end
  ev = run(r, 204, 204, 1)
  T.eq(ev[1].kind, "score"); T.eq(ev[1].pid, 2)
end)

T.case("event ends 75 s after spawn including ground time", function()
  local r = setup()
  local ev = run(r, 165, 254, 1)
  T.eq(ev[#ev].kind, "spawn", "still active at 74 s")
  ev = run(r, 255, 255, 1)
  T.eq(ev[1].kind, "ended"); T.eq(ev[1].reason, "timeout")
  T.eq(kinds(run(r, 256, 300, 1)), "", "no awards after end")
end)

T.case("drop awards full intervals already held", function()
  local r = setup()
  run(r, 165, 180, 1)
  r:pickup(1, 1180)
  local _, out = r:drop(1180 + 12.5)
  T.eq(out[1].kind, "score"); T.eq(out[1].pid, 1)
end)

T.case("overtime/finished clears and blocks further events", function()
  local r = setup()
  run(r, 165, 181, 1)
  r:pickup(1, 1181)
  local ev = r:tick(1190, 190, false)
  T.eq(ev[1].kind, "cleared")
  T.eq(r:carrier(), nil)
  T.eq(kinds(run(r, 350, 400, 1)), "", "no new relic after clear")
  T.eq(kinds(r:tick(1500, 500, false)), "")
end)

T.case("schedule 3/6/9/12/15 min; one relic at a time; past entries skipped after clock jump", function()
  local r = setup()
  local spawns = 0
  for _, e in ipairs(run(r, 0, 1000, 1)) do if e.kind == "spawn" then spawns = spawns + 1 end end
  T.eq(spawns, 5)
  local r2 = setup()
  local ev = r2:tick(1000 + 700, 700, true) -- jumped past 3:00 and 6:00 entirely, 9:00 too (540+75<700)
  T.eq(kinds(ev), "")
  ev = r2:tick(1000 + 705, 705, true)
  T.eq(ev[1].kind, "warning") -- 12:00 warning at 705
end)

T.case("view exposes timers without private data", function()
  local r = setup()
  T.eq(r:view(1000, 0).next_event_in, 180)
  run(r, 165, 180, 1)
  r:pickup(3, 1180)
  local v = r:view(1185, 185)
  T.eq(v.carrier, 3); T.eq(v.budget_left, 4); T.eq(v.remaining, 70); T.eq(v.next_point_in, 7)
end)

T.case("dev spawn/end do not consume the schedule", function()
  local r = setup()
  local ev = r:dev_spawn(1010)
  T.eq(ev[1].kind, "spawn")
  T.ok(r:pickup(1, 1011))
  T.eq(r:dev_end()[1].kind, "ended")
  T.eq(r.index, 1)
  T.eq(r:tick(1165, 165, true)[1].kind, "warning")
end)
