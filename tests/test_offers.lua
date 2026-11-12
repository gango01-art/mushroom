local Registry = require("rift.core.upgrade_registry")
local Offers = require("rift.core.offer_service")
local F = require("fixtures")

local function setup(seed, ups, dirs)
  local cfg = T.config()
  if not ups then ups, dirs = F.data() end
  local reg = Registry.new(ups, dirs)
  local s = Offers.new(cfg, reg, seed or 1)
  s:add_player(0, F.PA); s:add_player(1, F.PA)
  return s, cfg, reg
end

local function pending_of(s, pid, otype)
  for _, o in pairs(s.offers) do
    if o.owner == pid and o.status == "pending" and (not otype or o.type == otype) then return o end
  end
end

T.case("regular offers follow schedule, first offer is common only", function()
  local s, cfg, reg = setup()
  s:tick(10, 29, true)
  T.eq(pending_of(s, 0), nil)
  s:tick(11, 30, true)
  local o = pending_of(s, 0, "regular")
  T.ok(o, "offer at 30 s")
  T.eq(#o.options, 3)
  local seen = {}
  for _, id in ipairs(o.options) do
    T.eq(reg:get(id).rarity, "common"); T.ok(not seen[id], "distinct"); seen[id] = true
    T.eq(reg:get(id).required_direction, "any", "no direction-specific before choice")
  end
  T.eq(o.deadline - o.created_at, cfg.upgrades.offer_seconds)
end)

T.case("generation is reproducible for the same seed", function()
  local a = setup(99); local b = setup(99)
  a:tick(0, 30, true); b:tick(0, 30, true)
  local oa, ob = pending_of(a, 0), pending_of(b, 0)
  for i = 1, 3 do T.eq(oa.options[i], ob.options[i]) end
end)

T.case("choose: owner, option, double click, foreign offer", function()
  local s = setup()
  s:tick(0, 30, true)
  local o = pending_of(s, 0)
  local ok, why = s:choose(1, o.id, o.options[1], 1)
  T.ok(not ok); T.eq(why, "not_owner")
  ok, why = s:choose(0, o.id, "u_nonexistent", 1)
  T.ok(not ok); T.eq(why, "invalid_option")
  local ok2, _, applied = s:choose(0, o.id, o.options[2], 1)
  T.ok(ok2); T.eq(applied.rank, 1)
  ok, why = s:choose(0, o.id, o.options[2], 1.1)
  T.ok(not ok); T.eq(why, "already_resolved")
  T.eq(s:player(0).build[o.options[2]], 1, "applied once")
  ok, why = s:choose(0, 9999, "x", 1)
  T.eq(why, "unknown_offer")
end)

T.case("timeout applies safe fallback once; late choice rejected", function()
  local s, cfg = setup()
  s:tick(0, 30, true)
  local o = pending_of(s, 0)
  s:tick(cfg.upgrades.offer_seconds, 30 + cfg.upgrades.offer_seconds, true)
  T.eq(o.status, "resolved"); T.eq(o.resolution.by, "timeout"); T.eq(o.resolution.option, o.options[1])
  local ok, why = s:choose(0, o.id, o.options[2], 100)
  T.ok(not ok); T.eq(why, "already_resolved")
end)

T.case("no regular offers when regular_open = false (after 18:00)", function()
  local s = setup()
  s:tick(0, 2000, false)
  T.eq(pending_of(s, 0), nil)
end)

T.case("ultimate offer only on first real learn of the ultimate", function()
  local s = setup()
  T.eq(s:on_ability_learned(0, "phantom_assassin_stifling_dagger", 1, "player", 5), nil, "other ability")
  T.eq(s:on_ability_learned(0, F.ULT, 1, "dev_set_level", 5), nil, "dev level path never offers")
  local o = s:on_ability_learned(0, F.ULT, 1, "player", 5)
  T.ok(o); T.eq(o.type, "ultimate_direction"); T.eq(#o.options, 2)
  T.eq(o.options[1], "pa_phantom_execution"); T.eq(o.options[2], "pa_storm_daggers")
  T.eq(o.default_option, "pa_phantom_execution")
  local again, why = s:on_ability_learned(0, F.ULT, 2, "player", 6)
  T.eq(again, nil); T.eq(why, "already_offered")
  T.ok(s:ultimate_locked(0))
end)

T.case("level 6 / skill points alone never create the ultimate offer", function()
  local s = setup()
  -- the service has no level hook at all; only a learned-ability call can create it
  s:tick(0, 400, true)
  for _, o in pairs(s.offers) do T.ok(o.type ~= "ultimate_direction") end
end)

T.case("direction chosen once; next ranks do not reopen; unlocks ultimate", function()
  local s = setup()
  local o = s:on_ability_learned(0, F.ULT, 1, "player", 5)
  local ok, _, applied = s:choose(0, o.id, "pa_storm_daggers", 6)
  T.ok(ok); T.eq(applied.direction, "magical")
  T.ok(not s:ultimate_locked(0))
  T.eq(s:on_ability_learned(0, F.ULT, 2, "player", 50), nil)
  T.eq(s:on_ability_learned(0, F.ULT, 3, "player", 90), nil)
  T.eq(s:player(0).direction, "magical")
end)

T.case("two players of the same hero choose independent directions", function()
  local s = setup()
  local a = s:on_ability_learned(0, F.ULT, 1, "player", 5)
  local b = s:on_ability_learned(1, F.ULT, 1, "player", 5)
  s:choose(0, a.id, "pa_phantom_execution", 6)
  s:choose(1, b.id, "pa_storm_daggers", 6)
  T.eq(s:player(0).direction, "physical"); T.eq(s:player(1).direction, "magical")
end)

T.case("ultimate timeout picks the hero default", function()
  local s, cfg = setup()
  local o = s:on_ability_learned(0, F.ULT, 1, "player", 5)
  s:tick(5 + cfg.upgrades.offer_seconds, 0, false)
  T.eq(s:player(0).direction_id, "pa_phantom_execution")
  T.eq(o.resolution.by, "timeout")
end)

T.case("ultimate offer has display priority; regular keeps id, options and deadline", function()
  local s = setup()
  s:tick(0, 30, true)
  local reg = pending_of(s, 0, "regular")
  local opts, deadline = { reg.options[1], reg.options[2], reg.options[3] }, reg.deadline
  local ult = s:on_ability_learned(0, F.ULT, 1, "player", 10)
  T.eq(s:visible(0).id, ult.id)
  s:choose(0, ult.id, "pa_phantom_execution", 11)
  T.eq(s:visible(0).id, reg.id)
  for i = 1, 3 do T.eq(reg.options[i], opts[i]) end
  T.eq(reg.deadline, deadline)
end)

T.case("direction-specific upgrades appear only after matching direction", function()
  local s, _, reg = setup(3)
  local o = s:on_ability_learned(0, F.ULT, 1, "player", 0)
  s:choose(0, o.id, "pa_storm_daggers", 1)
  local p = s:player(0)
  for _, u in ipairs(s:candidates(p)) do
    T.ok(u.required_direction ~= "physical", "no physical after magical: " .. u.id)
  end
  local has_magic = false
  for _, u in ipairs(s:candidates(p)) do if u.required_direction == "magical" then has_magic = true end end
  T.ok(has_magic)
  -- prerequisite: conductive blade needs static edge
  for _, u in ipairs(s:candidates(p)) do T.ok(u.id ~= "pa_conductive_blade") end
  p.build.pa_static_edge = 1
  local found = false
  for _, u in ipairs(s:candidates(p)) do if u.id == "pa_conductive_blade" then found = true end end
  T.ok(found)
end)

T.case("maxed ranks are not offered; exhaustion gives bounded compensation", function()
  local ups, dirs = F.data()
  local s = setup(1, { ups[9] }, dirs)  -- only u_vitality (max 3)
  local p = s:player(0)
  p.build.u_vitality = 3
  s:tick(0, 30, true)
  local o = pending_of(s, 0)
  T.eq(o.type, "compensation"); T.eq(o.options[1], Offers.COMPENSATION)
  local ok, _, applied = s:choose(0, o.id, Offers.COMPENSATION, 1)
  T.ok(ok); T.eq(applied.kind, "gold")
end)

T.case("fewer than 3 valid options -> shows actual count", function()
  local ups, dirs = F.data()
  local s = setup(1, { ups[9], ups[10] }, dirs)
  s:tick(0, 30, true)
  T.eq(#pending_of(s, 0).options, 2)
end)

T.case("planned (unimplemented) entries are never offered", function()
  local ups, dirs = F.data("planned")
  local s = setup(1, ups, dirs)
  s:tick(0, 30, true)
  T.eq(pending_of(s, 0).type, "compensation")
end)

T.case("snapshot is private and restores pending + build", function()
  local s = setup()
  s:tick(0, 30, true)
  local snap = s:snapshot(0)
  T.eq(#snap.pending, 1)
  for _, o in ipairs(snap.pending) do T.eq(o.owner, 0) end
  local o = snap.pending[1]
  s:choose(0, o.id, o.options[1], 1)
  snap = s:snapshot(0)
  T.eq(#snap.pending, 0); T.eq(#snap.build, 1)
end)

T.case("events are emitted once per create/resolve", function()
  local s = setup()
  s:tick(0, 30, true)
  local ev = s:events()
  T.eq(#ev, 2) -- two players
  T.eq(#s:events(), 0)
end)

T.case("ultimate offer refused while directions are not implemented", function()
  local ups, dirs = F.data("shipped")
  local s = setup(1, ups, dirs)
  local o, why = s:on_ability_learned(0, F.ULT, 1, "player", 5)
  T.eq(o, nil); T.eq(why, "directions_not_implemented")
  T.ok(not s:ultimate_locked(0), "nothing locked when no offer")
end)

T.case("dev grant validates and does not touch schedule; dev offer is extra", function()
  local s = setup()
  local ok = s:dev_grant(0, "u_vitality", 0)
  T.ok(ok); T.eq(s:player(0).build.u_vitality, 1)
  local bad, why = s:dev_grant(0, "pa_storm_daggers", 0)
  T.ok(not bad); T.eq(why, "not_allowed")
  local o = s:dev_issue_regular(0, 0, 10)
  T.ok(o); T.eq(s:player(0).regular_issued, 0)
  s:tick(1, 30, true)
  T.eq(s:player(0).regular_issued, 1, "schedule still issues its own offer")
end)

T.case("dev_set_direction: own hero only, once, resolves pending offer", function()
  local ups, dirs = F.data("shipped")
  local s = setup(1, ups, dirs)
  T.eq(select(2, s:dev_set_direction(0, "ta_crystal_physical")), "wrong_hero")
  local ok = s:dev_set_direction(0, "pa_storm_daggers")
  T.ok(ok); T.eq(s:player(0).direction, "magical")
  T.eq(select(2, s:dev_set_direction(0, "pa_phantom_execution")), "already_chosen")
  T.eq(s:on_ability_learned(0, F.ULT, 1, "player", 5), nil, "no offer after forced direction")
end)
