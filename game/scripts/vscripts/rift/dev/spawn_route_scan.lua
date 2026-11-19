-- Samples candidate spawn locations inside the existing protected pockets.
-- Does not move any entity or edit terrain.
local gm=GameRules.RiftArena
assert(gm and gm.dev and PlayerResource:GetPlayerCount()==1,"single-player Tools only")
for _,b in ipairs(gm.map.bases)do
 local best,point,distance=1e9
 for x=-384,384,64 do for y=-384,384,64 do if x*x+y*y<=400*400 then
  local p=GetGroundPosition(Vector(b.x+x,b.y+y,b.z),nil)
  if p.z==128 and GridNav:IsTraversable(p)and not GridNav:IsBlocked(p)then
   local length=1e9
   for i=0,31 do local a=i*math.pi/16;local edge=Vector(math.cos(a)*900,math.sin(a)*900,128)
    if GridNav:CanFindPath(p,edge)then local d=GridNav:FindPathLength(p,edge);if d>0 then length=math.min(length,d)end end
   end
   local error=math.abs(length-2550)
   if error<best then best=error;point=p;distance=length end
  end
 end end end
 assert(point,"no safe candidate "..b.team)
 print(string.format("[RIFT][SPAWN_SCAN] team=%d x=%.0f y=%.0f distance=%.2f error=%.2f",b.team,point.x,point.y,distance,best))
end
