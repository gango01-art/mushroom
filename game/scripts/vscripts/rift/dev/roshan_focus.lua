-- Alternate pit viewpoints for the single-player Tools art review.
local gm=GameRules.RiftArena
assert(gm and gm.dev and PlayerResource:GetPlayerCount()==1 and not gm.map.fallback)
local hero=assert(PlayerResource:GetSelectedHeroEntity(0))
local index=gm._rift_pit_view==1 and 2 or 1
gm._rift_pit_view=index
local pit=gm.map.roshan_pockets[index]
local center=Vector(pit.x,pit.y,pit.z)
local entry=center-center:Normalized()*410
entry=GetGroundPosition(Vector(entry.x,entry.y,pit.z),hero)
FindClearSpaceForUnit(hero,entry,true)
hero:Stop()
AddFOWViewer(hero:GetTeamNumber(),center,1400,45,false)
PlayerResource:SetCameraTarget(0,hero)
hero:SetContextThink("rift_pit_camera",function()PlayerResource:SetCameraTarget(0,nil)end,.5)
print("[RIFT][PIT_VIEW] pit="..index.." entry="..tostring(entry))
