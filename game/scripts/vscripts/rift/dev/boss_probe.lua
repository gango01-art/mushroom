-- Explicit destructive single-player Tools test. Real units/AI/death/rewards;
-- only the migration deadline is moved forward, not movement or respawn time.
local gm=GameRules.RiftArena;local B=require("rift.core.config").roshan
assert(gm and gm.dev and PlayerResource:GetPlayerCount()==1 and not gm.lab.enabled,"normal single-player Tools required")
local h=assert(PlayerResource:GetSelectedHeroEntity(0));local s=assert(gm.roshan)
assert(s.unit and s.unit:IsAlive(),"Roshan missing")
local function log(t)print("[RIFT][BOSS_PROBE] "..t)end
local function place(p)FindClearSpaceForUnit(h,GetGroundPosition(p,h),true);h:Stop();PlayerResource:SetCameraTarget(0,h)end
local function home()local p=gm.sanctuary:home(h:GetTeamNumber());place(Vector(p.x,p.y,p.z))end
while h:GetLevel()<25 do h:HeroLevelUp(false)end
h:SetHealth(h:GetMaxHealth())
local hp;local phase="wait_start";local at=GameRules:GetGameTime()+.2
local gold,death_at,respawn_at,origin,boss_hp,target_pocket,toss_start,toss_hp,max_z,toss_origin
home()
local aegis_pos,aegis_deaths,aegis_deadline
GameRules:GetGameModeEntity():SetContextThink("rift_boss_probe",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime();if now<at then return .1 end
  if phase=="wait_start"then
   if s.travelling then at=now+.5;return .1 end
   place(s.unit:GetAbsOrigin()+Vector(180,0,0));h:SetHealth(h:GetMaxHealth());hp=h:GetHealth()
   phase="boss_attack";at=now+5
  elseif phase=="boss_attack"then
   log("Roshan actual AI damage="..(hp-h:GetHealth()));assert(h:GetHealth()<hp,"boss did not attack")
   home();phase="wait_combat";at=now+2
  elseif phase=="wait_combat"then
   local elapsed=gm.director.state:active_elapsed(gm:Now())
   assert(not s.travelling,"wait for previous migration to complete")
   target_pocket=s.index==1 and 2 or 1
   gm.clock_offset=gm.clock_offset+(target_pocket==2 and 300 or 600)-elapsed
   origin=s.unit:GetAbsOrigin();boss_hp=s.unit:GetHealth();phase="toss";at=now+.3;death_at=now+180
   local p=s.pockets[target_pocket];local direction=(Vector(p.x,p.y,p.z)-origin):Normalized()
   place(origin+direction*240);h:SetHealth(h:GetMaxHealth());toss_start=now;toss_hp=h:GetHealth();toss_origin=h:GetAbsOrigin();max_z=toss_origin.z
   log("migration clock advanced; checking native grab/throw before real walk")
  elseif phase=="toss"then
   max_z=math.max(max_z,h:GetAbsOrigin().z)
   if now-toss_start<4 then at=now+.03;return .03 end
   log("native toss damage="..(toss_hp-h:GetHealth()).." displacement="..(h:GetAbsOrigin()-toss_origin):Length2D().." max_z="..max_z.." count="..tostring(s.throw_count))
   assert((s.throw_count or 0)>0 and h:GetHealth()<toss_hp and(h:GetAbsOrigin()-toss_origin):Length2D()>300,"native grab/throw did not land")
   home();phase="walk";at=now+1;PlayerResource:SetCameraTarget(0,s.unit)
  elseif phase=="walk"then
   assert(now<death_at,"boss migration timed out")
   if s.index~=target_pocket or s.travelling then at=now+1;return .1 end
   assert((s.unit:GetAbsOrigin()-origin):Length2D()>5000,"boss did not cross arena")
   log("real migration arrived pocket="..s.index.." hp="..s.unit:GetHealth().." PASS")
   -- The real sanctuary filter correctly rejects damage from a hero at home.
   place(s.unit:GetAbsOrigin()+Vector(180,0,0));h:SetHealth(h:GetMaxHealth())
   phase="kill";at=now+.3
  elseif phase=="kill"then
   gold=PlayerResource:GetGold(0);s.unit:Kill(nil,h);death_at=now
   phase="loot";at=now+.2
  elseif phase=="loot"then
   local gain=PlayerResource:GetGold(0)-gold;assert(gain>=500 and gain<=503,"boss payout wrong "..gain)
   assert(s.aegis and not s.aegis:IsNull(),"Aegis drop missing")
   assert(s.aegis:GetContainedItem():GetAbilityName()=="item_aegis","wrong loot")
   respawn_at=s.respawn_at
   assert(math.abs(respawn_at-gm:Now()-300)<1,"boss respawn deadline wrong")
   log("gold="..gain.." native Aegis drop=1 respawn deadline300 PASS")
   place(s.aegis:GetAbsOrigin()+Vector(90,0,0))
   ExecuteOrderFromTable({UnitIndex=h:entindex(),OrderType=DOTA_UNIT_ORDER_PICKUP_ITEM,TargetIndex=s.aegis:entindex(),Queue=false})
   phase="aegis_pickup";at=now+3
  elseif phase=="aegis_pickup"then
   assert(h:HasModifier("modifier_item_aegis"),"native Aegis pickup failed")
   aegis_pos=h:GetAbsOrigin();aegis_deaths=gm.scoring:get(0).deaths;aegis_deadline=now+10
   h:Kill(nil,nil);phase="aegis_rebirth";at=now+.2
  elseif phase=="aegis_rebirth"then
   if not h:IsAlive()then assert(now<aegis_deadline,"Aegis revive timed out");at=now+.1;return .1 end
   assert((h:GetAbsOrigin()-aegis_pos):Length2D()<150,"Aegis teleported hero to sanctuary")
   assert(gm.scoring:get(0).deaths==aegis_deaths,"Aegis incorrectly counted as PvP death")
   log("native Aegis pickup and real rebirth in place without death score PASS")
   phase="respawn";at=now+1;home()
   local ok,e=pcall(require,"rift.dev.relic_probe");if not ok then log("relic start ERROR "..tostring(e))end
  elseif phase=="respawn"then
   if now-death_at<299 then assert(not s.unit,"early Roshan respawn");at=now+1;return .1 end
   if not s.unit then assert(now-death_at<303,"late Roshan respawn");at=now+.1;return .1 end
   log("actual respawn after="..(now-death_at).." seconds pocket="..s.index.." PASS")
   PlayerResource:SetCameraTarget(0,s.unit);log("DONE");return nil
  end
  return .1
 end)
 if not ok then log("ERROR "..tostring(result));home();PlayerResource:SetCameraTarget(0,nil);return nil end
 return result
end,.1)
