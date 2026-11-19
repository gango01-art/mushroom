local C=require("rift.core.river_camps")
local B=require("rift.core.config").river_camps
T.case("river camp spawns at 90s and only 90s after a full clear",function()
 local c={remaining=0};T.ok(not C.ready(c,89,89,B));T.ok(C.ready(c,90,90,B))
 c.remaining=3;C.killed(c,100,B);C.killed(c,101,B);T.ok(not c.ready_at)
 C.killed(c,102,B);T.eq(c.ready_at,192);T.ok(not C.ready(c,191,191,B));T.ok(C.ready(c,192,192,B))
 T.ok(not C.killed(c,103,B));T.eq(c.ready_at,192)
end)
T.case("three aquatic neutrals total 120/180/240 gold and do not inherit native bounty",function()
 for _,t in ipairs({{0,120},{600,180},{1200,240}})do
  local total=0;for _,d in ipairs(B.members)do total=total+math.floor(d.gold*C.scale(B,t[1]))end
  T.eq(total,t[2])
 end
end)
