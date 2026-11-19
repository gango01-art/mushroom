-- Explicit single-player Tools reproduction / repeat after terrain build.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local lab=gm.lab;lab:Clear();local c=PlayerResource:GetSelectedHeroEntity(lab.owner)
for _,p in ipairs({{0,0},{-640,0},{640,0},{0,-640},{0,640},{2400,0},{-2400,0},{0,2400},{0,-2400},{3200,0},{-3200,0}})do
 local v=GetGroundPosition(Vector(p[1],p[2],0),c)
 print("[RIFT][CENTER] sample "..p[1]..","..p[2].." z="..v.z.." traversable="..tostring(GridNav:IsTraversable(v)).." blocked="..tostring(GridNav:IsBlocked(v)))
end
FindClearSpaceForUnit(c,GetGroundPosition(Vector(-640,0,0),c),true);c:Stop();c:MoveToPosition(Vector(0,0,128))
PlayerResource:SetCameraTarget(lab.owner,c)
GameRules:GetGameModeEntity():SetContextThink("rift_center_repro",function()
 local p=c:GetAbsOrigin();c:Stop();PlayerResource:SetCameraTarget(lab.owner,nil)
 print("[RIFT][CENTER] walk-to-origin remaining="..p:Length2D().." actual="..p.x..","..p.y..","..p.z)
 return nil
end,4)
