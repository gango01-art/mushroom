local gm=GameRules.RiftArena
assert(gm and gm.dev and PlayerResource:GetPlayerCount()==1,"single-player Tools required")
for q=0,3 do
 local best,choice=-1
 for r=3200,4100,64 do for d=-4,36,4 do
  local a=math.rad(d+q*90);local p=GetGroundPosition(Vector(math.cos(a)*r,math.sin(a)*r,0),nil)
  local valid=p.z==0 and GridNav:IsTraversable(p)and not GridNav:IsBlocked(p)and GridNav:CanFindPath(Vector(0,0,128),p)
  for i=0,7 do local aa=i*math.pi/4;local v=GetGroundPosition(p+Vector(math.cos(aa)*160,math.sin(aa)*160,0),nil)
   valid=valid and v.z==0 and GridNav:IsTraversable(v)and not GridNav:IsBlocked(v)
  end
  for _,b in ipairs(gm.map.bases)do valid=valid and (p-Vector(b.tower.x,b.tower.y,0)):Length2D()>1000 end
  if valid and r>best then best=r;choice=p end
 end end
 assert(choice,"no spacious water pocket quadrant="..q)
 print(string.format("[RIFT][RIVER_POCKET] quadrant=%d x=%.0f y=%.0f radius=%d room160 PASS",q,choice.x,choice.y,best))
end
