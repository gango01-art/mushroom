-- Native map/nav sampling. Explicit Tools console load only.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab:Allowed(0),"single-player Tools required")
assert(gm.map and not gm.map.fallback,"real arena required")
local function log(s)print("[RIFT][ARENA_NATIVE] "..s)end
local center=Vector(gm.map.center.x,gm.map.center.y,gm.map.center.z)
center=GetGroundPosition(center,nil)
log("center traversable="..tostring(GridNav:IsTraversable(center)).." blocked="..tostring(GridNav:IsBlocked(center)).." z="..center.z)
for _,offset in ipairs({Vector(0,-600,0),Vector(600,0,0),Vector(-600,0,0)})do
 local p=GetGroundPosition(center+offset,nil)
 log("inner "..tostring(offset).." traversable="..tostring(GridNav:IsTraversable(p)).." blocked="..tostring(GridNav:IsBlocked(p)).." path="..tostring(GridNav:CanFindPath(center,p)))
end
assert(GridNav:IsTraversable(center) and not GridNav:IsBlocked(center), "center must itself be walkable")
local pass,fail=0,0
for _,p in ipairs(gm.map.spawns)do
 local point=GetGroundPosition(Vector(p.x,p.y,p.z),nil)
 local ok=GridNav:IsTraversable(point)and not GridNav:IsBlocked(point)
 local path=require("rift.engine.log").try(GridNav,"Arena nav","CanFindPath",center,point)
 log(p.name.." traversable="..tostring(ok).." connected="..tostring(path).." z="..point.z)
 if ok and path then pass=pass+1 else fail=fail+1 end
end
for _,team in ipairs({2,3,6,7,8,9,10,11})do
 local e=assert(Entities:FindByName(nil,"rift_team_start_"..team),"team start missing")
 local point=GetGroundPosition(e:GetAbsOrigin(),nil)
 local ok=GridNav:IsTraversable(point)and not GridNav:IsBlocked(point)
 local path=require("rift.engine.log").try(GridNav,"Arena nav","CanFindPath",center,point)
 log("base team="..team.." traversable="..tostring(ok).." connected="..tostring(path).." z="..point.z)
 if ok and path then pass=pass+1 else fail=fail+1 end
end
for _,p in ipairs(gm.map.relics)do
 local point=GetGroundPosition(Vector(p.x,p.y,p.z),nil)
 local ok=GridNav:IsTraversable(point)and not GridNav:IsBlocked(point)
 local path=GridNav:CanFindPath(center,point)
 log(p.name.." traversable="..tostring(ok).." connected="..tostring(path))
 if ok and path then pass=pass+1 else fail=fail+1 end
end
log("RESULT pass="..pass.." fail="..fail.." total=24; path sampling does not replace full manual traversal")
