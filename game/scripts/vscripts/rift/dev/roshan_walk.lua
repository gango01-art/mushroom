-- Move the actual hero across the river approaches, in a single-player Tools match.
local gm=GameRules.RiftArena
assert(gm and gm.dev and PlayerResource:GetPlayerCount()==1 and not gm.map.fallback)
local h=assert(PlayerResource:GetSelectedHeroEntity(0))
local home=assert(gm.sanctuary:home(h:GetTeamNumber())).spawn
FindClearSpaceForUnit(h,Vector(home.x,home.y,home.z),true)
h:Stop()
local targets={gm.map.center,gm.map.roshan_pockets[1],gm.map.roshan_pockets[2]}
local i,goal,started=0,nil,nil
local function done(message)
 h:Stop();PlayerResource:SetCameraTarget(0,nil)
 print("[RIFT][PATH_WALK] "..message)
end
PlayerResource:SetCameraTarget(0,h)
GameRules:GetGameModeEntity():SetContextThink("rift_roshan_walk",function()
 local now=GameRules:GetGameTime()
 if not h:IsAlive()then return done("hero died before finishing")end
 if goal then
  local remaining=(h:GetAbsOrigin()-goal):Length2D()
  if remaining>165 then
   if now-started>70 then return done("blocked leg="..i.." at "..tostring(h:GetAbsOrigin()))end
   return .2
  end
  print(string.format("[RIFT][PATH_WALK] PASS leg=%d seconds=%.1f",i,now-started))
 end
 i=i+1
 local p=targets[i]
 if not p then return done("DONE base → center → NW pit → SE pit")end
 goal=GetGroundPosition(Vector(p.x,p.y,p.z),h)
 started=now
 h:MoveToPosition(goal)
 return .2
end,.1)
