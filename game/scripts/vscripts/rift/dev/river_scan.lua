local gm=GameRules.RiftArena
assert(gm and gm.dev and not gm.map.fallback,"real Tools arena required")
local floor=GetGroundPosition(Vector(0,-1800,128),nil)
for i=0,3 do
 for _,r in ipairs({2900,3100,3300,3500})do for _,degrees in ipairs({0,8,16,24})do
  local a=math.rad(degrees)+i*math.pi/2
  local p=GetGroundPosition(Vector(math.cos(a)*r,math.sin(a)*r,0),nil)
  if p.z<1 and GridNav:IsTraversable(p)and not GridNav:IsBlocked(p)and GridNav:CanFindPath(floor,p)then
   print("[RIFT][RIVER_SCAN] quadrant="..i.." candidate="..math.floor(p.x)..","..math.floor(p.y).." z="..p.z)
  end
 end end
end
