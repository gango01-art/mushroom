-- Read-only search of existing river water near the two unused outer pockets.
local gm=GameRules.RiftArena
assert(gm and gm.dev and PlayerResource:GetPlayerCount()==1)
for pit,old in ipairs(gm.map.roshan_pockets)do
 local angle=math.atan2(old.y,old.x)
 for _,room in ipairs({160,240,320})do
  local best,choice=1e9
  for r=3000,4400,64 do for degrees=-24,24,4 do
   local a=angle+math.rad(degrees);local p=GetGroundPosition(Vector(math.cos(a)*r,math.sin(a)*r,0),nil)
   local valid=p.z==0 and GridNav:IsTraversable(p)and not GridNav:IsBlocked(p)and GridNav:CanFindPath(Vector(0,0,128),p)
   for i=0,15 do local aa=i*math.pi/8;local q=GetGroundPosition(p+Vector(math.cos(aa)*room,math.sin(aa)*room,0),nil)
    valid=valid and q.z==0 and GridNav:IsTraversable(q)and not GridNav:IsBlocked(q)
   end
   for _,b in ipairs(gm.map.bases)do valid=valid and(p-Vector(b.x,b.y,0)):Length2D()>1000 end
   for _,c in ipairs(gm.map.river_camps)do valid=valid and(p-Vector(c.x,c.y,0)):Length2D()>1000 end
   local distance=(p-Vector(old.x,old.y,0)):Length2D()
   if valid and distance<best then best=distance;choice=p end
  end end
  if choice then print(string.format("[RIFT][ROSHAN_WATER] pit=%d room=%d x=%.0f y=%.0f z=0 old_distance=%.1f",pit,room,choice.x,choice.y,best))
  else print("[RIFT][ROSHAN_WATER] pit="..pit.." room="..room.." no existing river clearance")end
 end
end
