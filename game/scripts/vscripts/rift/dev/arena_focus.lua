-- Read-only camera target for visual inspection of the actual compiled map.
local gm=GameRules.RiftArena
assert(gm and gm.dev and PlayerResource:GetPlayerCount()==1,"single-player Tools only")
local h=PlayerResource:GetSelectedHeroEntity(0)
FindClearSpaceForUnit(h,Vector(0,0,128),true);h:Stop();PlayerResource:SetCameraTarget(0,h)
print("[RIFT][FOCUS] center ground="..GetGroundPosition(Vector(0,0,0),nil).z)
for _,t in ipairs(gm.teams)do for i=0,15 do local a=i*math.pi/8
 assert(IsLocationVisible(t,Vector(math.cos(a)*880,math.sin(a)*880,128)),"public edge missing "..t)
end end
print("[RIFT][FOCUS] public center vision 8x16 PASS")
