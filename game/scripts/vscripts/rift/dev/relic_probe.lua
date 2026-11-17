-- Real pickup, timed scoring, death drop and cleanup in a single-player match.
local gm=GameRules.RiftArena;local h=PlayerResource:GetSelectedHeroEntity(0);local s=gm.relic
assert(gm.dev and PlayerResource:GetPlayerCount()==1 and not gm.lab.enabled,"normal single-player Tools only")
local function log(t)print("[RIFT][RELIC_PROBE] "..t)end
local function place(p)FindClearSpaceForUnit(h,GetGroundPosition(p,h),true);h:Stop();PlayerResource:SetCameraTarget(0,h)end
local function points()return gm.scoring:get(0).score end
s:DevEnd(gm:Now());place(Vector(0,-1600,128));assert(s:DevSpawn(gm:Now()))
local phase="model";local at=GameRules:GetGameTime()+6;local score,drop_pos
GameRules:GetGameModeEntity():SetContextThink("rift_relic_probe",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime();if now<at then return .1 end
  if phase=="model"then
   assert(s.ground_model and not s.ground_model:IsNull()and s.ground_fx,"persistent ground visuals missing")
   for _,team in ipairs(gm.teams)do assert(IsLocationVisible(team,s.ground_pos),"ground relic invisible to team="..team)end
   log("model+particle still present after6s, public vision8/8 PASS")
   score=points();place(s.ground_pos);phase="pickup";at=now+.6
  elseif phase=="pickup"then
   assert(s.relic:carrier()==0 and h:HasModifier("modifier_rift_relic_carrier"),"proximity pickup failed")
   assert(not s.ground_model and not s.ground_fx,"ground visuals not removed on pickup")
   log("real proximity pickup+carrier effect PASS");phase="score";at=now+12.5
  elseif phase=="score"then
   assert(points()==score+1,"timed relic point missing");drop_pos=h:GetAbsOrigin()
   log("one point after12s PASS");h:Kill(nil,nil);phase="death";at=now+.5
  elseif phase=="death"then
   assert(s.relic.state=="ground"and(s.ground_pos-drop_pos):Length2D()<100,"death did not drop relic")
   assert(not h:HasModifier("modifier_rift_relic_carrier"),"dead carrier kept buff")
   log("actual death drops model/particle and removes buff PASS")
   phase="revive";at=now+.5
  elseif phase=="revive"then
   if not h:IsAlive()then at=now+.5;return .1 end
   place(s.ground_pos);phase="end";at=now+.6
  elseif phase=="end"then
   assert(s.relic:carrier()==0,"second pickup failed")
   s:DevEnd(gm:Now())
   assert(not h:HasModifier("modifier_rift_relic_carrier")and not s.ground_model and not s.ground_fx,"ended event leaked effects")
   log("end removes all effects PASS; DONE");PlayerResource:SetCameraTarget(0,nil);return nil
  end
  return .1
 end)
 if not ok then log("ERROR "..tostring(result));PlayerResource:SetCameraTarget(0,nil);return nil end
 return result
end,.1)
