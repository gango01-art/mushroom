-- Bounded real movement smoke check. Only explicit single-player Tools lab.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),'single-player lab required')
assert(not gm.map.fallback,'real arena required')
require('rift.dev.arena_probe')
local c=assert(PlayerResource:GetSelectedHeroEntity(gm.lab.owner))
gm.lab:Clear();c:Stop()
local points={Vector(0,-2200,0),Vector(gm.map.spawns[1].x,gm.map.spawns[1].y,0),Vector(gm.map.spawns[6].x,gm.map.spawns[6].y,0)}
FindClearSpaceForUnit(c,GetGroundPosition(Vector(0,-600,0),c),true)
PlayerResource:SetCameraTarget(gm.lab.owner,c)
local i,start,deadline,goal=0
local function log(s)print('[RIFT][ARENA_WALK] '..s)end
GameRules:GetGameModeEntity():SetContextThink('rift_arena_walk',function()
 if c:IsNull()or not c:IsAlive()then log('ERROR hero unavailable');return nil end
 local now=GameRules:GetGameTime()
 if goal then
  local d=(c:GetAbsOrigin()-goal):Length2D()
  if d<100 then log(string.format('PASS leg=%d time=%.1f distance=%.1f',i,now-start,d));goal=nil
  elseif now>deadline then c:Stop();PlayerResource:SetCameraTarget(gm.lab.owner,nil);log(string.format('ERROR leg=%d remaining=%.1f',i,d));return nil
  else return .25 end
 end
 i=i+1
 if not points[i]then PlayerResource:SetCameraTarget(gm.lab.owner,nil);log('DONE 3/3 actual movement legs; not a full perimeter/shop test');return nil end
 goal=GetGroundPosition(points[i],c);start=now;deadline=now+75
 c:MoveToPosition(goal);log('START leg='..i)
 return .25
end,.1)
