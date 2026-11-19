local gm=GameRules.RiftArena
assert(gm and gm.dev and not gm.map.fallback,"real Tools arena required")
local center=GetGroundPosition(Vector(gm.map.center.x,gm.map.center.y,gm.map.center.z),nil)
local radius=require("rift.core.config").center_gold.radius
local low,high=1e9,0
for _,b in ipairs(gm.map.bases)do
 local p=b.spawn or b;local home=GetGroundPosition(Vector(p.x,p.y,p.z),nil);local best=1e9
 for i=0,31 do
  local a=i*math.pi/16;local edge=GetGroundPosition(center+Vector(math.cos(a)*radius,math.sin(a)*radius,0),nil)
  if GridNav:IsTraversable(edge)and not GridNav:IsBlocked(edge)and GridNav:CanFindPath(home,edge)then
   local d=GridNav:FindPathLength(home,edge)
   if d>0 then best=math.min(best,d)end
  end
 end
 print("[RIFT][ROUTES] team="..b.team.." to_gold_edge="..best.." seconds_at_300="..best/300)
 low=math.min(low,best);high=math.max(high,best)
end
print("[RIFT][ROUTES] min="..low.." max="..high.." spread="..(high-low).." seconds_spread_at_300="..(high-low)/300)
for _,p in ipairs(gm.map.river_camps)do
 local pos=GetGroundPosition(Vector(p.x,p.y,p.z),nil);local distance=1e9
 for _,b in ipairs(gm.map.bases)do distance=math.min(distance,(pos-Vector(b.tower.x,b.tower.y,b.tower.z)):Length2D())end
 print("[RIFT][ROUTES] "..p.name.." z="..pos.z.." traversable="..tostring(GridNav:IsTraversable(pos)).." blocked="..tostring(GridNav:IsBlocked(pos)).." center_connected="..tostring(GridNav:CanFindPath(center,pos)).." nearest_tower="..distance)
end
