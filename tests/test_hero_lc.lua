local B = require("rift.data.hero_balance")
local Duel = require("rift.core.heroes.lc_duel")
local M = require("rift.core.heroes.lc_magic")
local C = B.lc.duel_physical
local function near(a, b, msg) T.ok(math.abs(a - b) < 1e-9, (msg or "near") .. ": " .. a .. " vs " .. b) end

-- run a duel with a champion hit every 0.5 s; returns total paid and result
local function run(rank, until_t, hits)
  local st = Duel.new_owner_state()
  local d = Duel.start(C, rank, st, "t", 0, 1.0)
  local res, total = nil, 0
  local t = 0
  while t <= until_t + 1e-9 do
    if hits and hits(t) then d:record_champion_hit(t, 10) end
    local r = d:tick(t, 100)
    total = total + (r and r.payout or 0)
    if r and r.ended then res = r; break end
    t = t + 0.25
  end
  return total, res, d, st
end

T.case("full 10 s duel: exactly 10 payouts = 8 / 11 / 14, ends by timeout", function()
  for rank, want in ipairs({ 8, 11, 14 }) do
    local total, res, d = run(rank, 12, function() return true end)
    near(total, want, "rank " .. rank); T.eq(d.payouts, 10); T.eq(res.reason, "timeout")
    T.eq(res.penalty, nil, "timeout has no penalty")
  end
end)

T.case("no hits -> no income", function()
  local total = run(3, 12, function() return false end)
  near(total, 0)
end)

T.case("victory tops up to 12 / 16.5 / 21 total, not on top", function()
  for rank, want in ipairs({ 12, 16.5, 21 }) do
    local st = Duel.new_owner_state()
    local d = Duel.start(C, rank, st, "t", 0, 1.0)
    for t = 0, 3, 0.5 do d:record_champion_hit(t, 300); d:tick(t, 100) end
    local before = d.paid
    T.ok(before > 0)
    local r = d:resolve_deaths(false, true, 1000)
    T.eq(r.reason, "victory")
    near(d.paid, want, "rank " .. rank)
    near(r.payout, want - before)
  end
end)

T.case("example: rank 3, paid 4.2 -> add 16.8 -> 21", function()
  local st = Duel.new_owner_state()
  local d = Duel.start(C, 3, st, "t", 0, 1.0)
  d:record_champion_hit(0.5, 1000)
  for t = 0.5, 3, 0.5 do d:record_champion_hit(t, 0); d:tick(t, 0) end
  near(d.paid, 4.2)
  local r = d:resolve_deaths(false, true, 1000)
  near(r.payout, 16.8); near(st.earned, 21)
end)

T.case("victory needs 20% champion damage; third-party kill ends without victory", function()
  local st = Duel.new_owner_state()
  local d = Duel.start(C, 2, st, "t", 0, 1.0)
  d:record_champion_hit(0.5, 150)
  local r = d:resolve_deaths(false, true, 1000)
  T.eq(r.reason, "target_lost"); near(r.payout, 0)
end)

T.case("champion death: one penalty and stun; mutual death -> champion_death, no victory", function()
  local st = Duel.new_owner_state()
  local d = Duel.start(C, 1, st, "t", 0, 1.0)
  d:record_champion_hit(0.5, 900)
  local r = d:resolve_deaths(true, true, 1000)
  T.eq(r.reason, "champion_death"); near(r.penalty.max_hp_fraction, 0.30); near(r.penalty.stun, 1.0)
  T.eq(d:resolve_deaths(true, false, 1000), nil, "repeated death callback ignored")
  T.eq(d:abort("match_finished"), nil)
end)

T.case("leash break after > 1 s beyond 900, without victory or penalty", function()
  local st = Duel.new_owner_state()
  local d = Duel.start(C, 1, st, "t", 0, 1.0)
  T.ok(not d:tick(0.5, 1000).ended)
  T.ok(not d:tick(1.4, 1000).ended)
  local r = d:tick(1.6, 1000)
  T.eq(r.reason, "leash_break"); T.eq(r.penalty, nil)
  local d2 = Duel.start(C, 1, st, "t2", 0, 1.0)
  d2:tick(0.5, 1000); d2:tick(1.0, 100); T.ok(not d2:tick(2.0, 1000).ended, "grace resets inside leash")
end)

T.case("pause does not speed up income (time-based)", function()
  local st = Duel.new_owner_state()
  local d = Duel.start(C, 1, st, "t", 0, 1.0)
  d:record_champion_hit(0.9, 10)
  for _ = 1, 50 do d:tick(0.9, 100) end -- many thinker calls at the same paused time
  near(d.paid, 0)
  d:tick(1.0, 100); near(d.paid, 0.8)
end)

T.case("permanent cap 100 / 140 / 180 across sessions", function()
  local st = Duel.new_owner_state()
  st.earned = 99.5
  local d = Duel.start(C, 1, st, "t", 0, 1.0)
  d:record_champion_hit(0.5, 1000); d:tick(1, 0)
  near(st.earned, 100)
  d:record_champion_hit(1.5, 1000); d:tick(2, 0)
  near(st.earned, 100)
end)

T.case("anti-feed multiplier on repeated duels vs same target", function()
  local cfg = T.config()
  local st = Duel.new_owner_state()
  T.eq(Duel.pair_multiplier(st, "v", 0, cfg.anti_feed), 1.0)
  T.eq(Duel.pair_multiplier(st, "v", 30, cfg.anti_feed), 0.5)
  T.eq(Duel.pair_multiplier(st, "w", 31, cfg.anti_feed), 1.0)
  T.eq(Duel.pair_multiplier(st, "v", 200, cfg.anti_feed), 1.0, "window expired")
end)

-- magical -------------------------------------------------------------------
local MC = B.lc.duel_magical
T.case("spell amp = min(cap, base + earned); rank 0 -> 0; break suspends", function()
  local s = M.new_owner_state()
  T.eq(M.spell_amp(s, MC, 0), 0)
  T.eq(M.spell_amp(s, MC, 1), 3)
  M.credit(s, MC, "kill", "d1", 1); M.credit(s, MC, "assist", "d2", 1)
  near(M.spell_amp(s, MC, 1), 4.5)
  for i = 1, 30 do M.credit(s, MC, "kill", "k" .. i, 1) end
  T.eq(M.spell_amp(s, MC, 1), 10); T.eq(M.spell_amp(s, MC, 3), 20)
  T.eq(M.spell_amp(s, MC, 3, true), 0, "break")
  near(M.spell_amp(s, MC, 3), 20, "earned kept after break")
end)

T.case("rank-up changes base/cap without re-granting history; duplicate death ignored", function()
  local s = M.new_owner_state()
  M.credit(s, MC, "kill", "d1", 1)
  T.eq(M.credit(s, MC, "kill", "d1", 1), 0)
  T.eq(M.spell_amp(s, MC, 1), 4); T.eq(M.spell_amp(s, MC, 2), 6)
  near(M.credit(s, MC, "assist", "d3", 0.5), 0.25, "anti-feed multiplier, no rounding")
end)

local SC = B.lc.statue
T.case("statue: max four shots, missed slots never burst", function()
  local st = M.Statue.new(SC, 1, 0)
  T.eq(#st:due_shots(0.4), 0)
  T.eq(st:due_shots(0.5)[1], 1)
  local d = st:due_shots(9.6) -- lag: slots 2..4 due at once -> only the latest fires
  T.eq(#d, 1); T.eq(d[1], 4)
  T.eq(#st:due_shots(20), 0)
  T.ok(st:expired(10))
end)

T.case("statue: four hits reduce cooldown by 8 (not 16); only real enemy heroes; once per arrow", function()
  local st = M.Statue.new(SC, 2, 0)
  local cd = SC.cooldown
  for i = 1, 4 do
    cd = M.reduce_cooldown(cd, st:on_arrow_hit(i, true))
    cd = M.reduce_cooldown(cd, st:on_arrow_hit(i, true)) -- duplicate hit event
  end
  T.eq(st.total_cdr, 8); T.eq(cd, 17)
  T.eq(st:on_arrow_hit(99, false), 0, "creep/illusion hit")
  T.eq(M.reduce_cooldown(1, 2), 0, "never negative")
  T.eq(st:arrow_damage(), 90); T.eq(st:health(), 550)
end)
