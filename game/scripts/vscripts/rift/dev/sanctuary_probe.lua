-- Real terrain, aura, dispel, combat-filter and automatic guardian test.
-- Explicit single-player Tools lab only. The hero/team is not replaced.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
assert(gm.sanctuary and #gm.sanctuary.bases==8,"eight real sanctuary bases required")
local B=require("rift.core.config").sanctuary
local c=PlayerResource:GetSelectedHeroEntity(gm.lab.owner)
local home=assert(gm.sanctuary:home(c:GetTeamNumber()));local tower=assert(gm.sanctuary.towers[home.team])
local start=c:GetAbsOrigin();local u,pet
local function log(s)print("[RIFT][SANCTUARY] "..s)end
local function cleanup()
 if tower and not tower:IsNull()then tower:RemoveModifierByName("modifier_disarmed")end
 for _,v in ipairs({u,pet})do if v and not v:IsNull()then UTIL_Remove(v)end end
 if c and not c:IsNull()then
  c:RemoveModifierByName("modifier_stunned");c:Stop()
  FindClearSpaceForUnit(c,GetGroundPosition(start,c),true)
  PlayerResource:SetCameraTarget(gm.lab.owner,nil)
 end
end
local low,high,samples=1e9,-1e9,0
for x=-800,800,100 do for y=-800,800,100 do
 if x*x+y*y<=800*800 then
  local p=GetGroundPosition(Vector(x,y,0),nil);low=math.min(low,p.z);high=math.max(high,p.z);samples=samples+1
 end
end end
log("flat samples="..samples.." z_min="..low.." z_max="..high)
assert(high-low<1,"central terrain not flat")
local center=GetGroundPosition(Vector(0,0,0),nil)
assert(GridNav:IsTraversable(center)and not GridNav:IsBlocked(center),"center still blocked")
local count=0
for _,base in ipairs(gm.sanctuary.bases)do
 local p=GetGroundPosition(Vector(base.x,base.y,base.z),nil)
 assert(GridNav:IsTraversable(p)and not GridNav:IsBlocked(p)and GridNav:CanFindPath(center,p),"base disconnected team="..base.team)
 local guard=gm.sanctuary.towers[base.team]
 assert(guard and not guard:IsNull(),"guardian missing")
 assert((guard:GetAbsOrigin()-Vector(base.tower.x,base.tower.y,base.tower.z)):Length2D()<5,"guardian misplaced team="..base.team)
 count=count+1
end
log("bases connected/guardians="..count.."/8; center walkable")
gm.lab:Clear()
local inward=Vector(-home.x,-home.y,0):Normalized()
local outside=GetGroundPosition(Vector(home.x,home.y,home.z)+inward*1200,c)
FindClearSpaceForUnit(c,outside,true);c:Stop()
assert(not gm.sanctuary:sheltered(c),"outside setup failed")
tower:AddNewModifier(tower,nil,"modifier_disarmed",{duration=20})
local enemy_team=c:GetTeamNumber()==2 and 3 or 2
u=CreateUnitByName("npc_dota_hero_axe",outside+Vector(180,0,0),true,nil,nil,enemy_team)
u:SetRespawnsDisabled(true);u:SetIdleAcquire(false);u:Stop();u:SetBaseMaxHealth(10000);u:SetMaxHealth(10000);u:SetHealth(10000)
c:AddNewModifier(u,nil,"modifier_stunned",{duration=5})
assert(c:HasModifier("modifier_stunned"),"pre-entry stun was not applied")
c:SetHealth(math.max(1,math.floor(c:GetMaxHealth()*.2)));c:SetMana(c:GetMaxMana()*.2)
local hp,mp=c:GetHealth(),c:GetMana()
gm:PlaceAtSpawn(c,gm.lab.owner)
assert((c:GetAbsOrigin()-Vector(home.x,home.y,home.z)):Length2D()<100,"respawn did not use own base")
local phase,at="enter",GameRules:GetGameTime()+1.1
GameRules:GetGameModeEntity():SetContextThink("rift_sanctuary_probe",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime()
  if now<at then return .05 end
  if phase=="enter"then
   assert(c:HasModifier("modifier_rift_sanctuary"),"sanctuary aura missing")
   assert(not c:HasModifier("modifier_stunned"),"strong dispel did not remove entry stun")
   local dh,dm=c:GetHealth()-hp,c:GetMana()-mp
   assert(dh>c:GetMaxHealth()*.12 and dm>c:GetMaxMana()*.12,"regeneration too low")
   log("home spawn and strong dispel PASS; 1.1s hp_gain="..dh.." mana_gain="..dm)
   hp=c:GetHealth();ApplyDamage({victim=c,attacker=u,damage=100000,damage_type=DAMAGE_TYPE_PURE})
   assert(c:IsAlive()and c:GetHealth()==hp,"lethal damage penetrated sanctuary")
   local before=u:GetHealth();ApplyDamage({victim=u,attacker=c,damage=1000,damage_type=DAMAGE_TYPE_PURE})
   assert(u:GetHealth()==before,"outgoing damage bypassed sanctuary")
   c:AddNewModifier(u,nil,"modifier_stunned",{duration=5});assert(not c:HasModifier("modifier_stunned"),"incoming hostile modifier bypass")
   u:AddNewModifier(c,nil,"modifier_stunned",{duration=5});assert(not u:HasModifier("modifier_stunned"),"outgoing hostile modifier bypass")
   pet=CreateUnitByName("npc_rift_lc_champion",outside,true,c,c,c:GetTeamNumber())
   pet:SetOwner(c);pet:SetControllableByPlayer(gm.lab.owner,true);pet:SetIdleAcquire(false);pet:Stop()
   before=u:GetHealth();ApplyDamage({victim=u,attacker=pet,damage=1000,damage_type=DAMAGE_TYPE_PURE})
   assert(u:GetHealth()==before,"summon damage bypass")
   log("lethal100000/outgoing1000/debuffs/summon blocked PASS; summon_owner="..pet:GetPlayerOwnerID())
   FindClearSpaceForUnit(c,outside,true);phase="leave";at=now+.35
  elseif phase=="leave"then
   assert(not c:HasModifier("modifier_rift_sanctuary"),"protection lingered outside")
   local before=u:GetHealth();ApplyDamage({victim=u,attacker=c,damage=100,damage_type=DAMAGE_TYPE_PURE})
   assert(u:GetHealth()<before,"combat did not resume outside")
   log("exit clears protection and restores outgoing damage PASS")
   c:Stop();tower:RemoveModifierByName("modifier_disarmed")
   local target=GetGroundPosition(tower:GetAbsOrigin()+inward*180,u)
   FindClearSpaceForUnit(u,target,true);u:Stop();u:SetHealth(u:GetMaxHealth())
   local guardian_pos=tower:GetAbsOrigin();hp=(u:GetAbsOrigin()-guardian_pos):Length2D()
   local m=tower:FindModifierByName("modifier_rift_base_guardian");mp=m.knockbacks or 0
   phase="push";at=now+.1;gm._rift_guard_deadline=now+5
  elseif phase=="push"then
   local m=tower:FindModifierByName("modifier_rift_base_guardian")
   local distance=(u:GetAbsOrigin()-tower:GetAbsOrigin()):Length2D()-hp
   if (m.knockbacks or 0)>mp and distance>400 then
    log("automatic real guardian hit pushed="..distance.." PASS; DONE")
    cleanup();return nil
   end
   assert(now<gm._rift_guard_deadline,"guardian did not automatically push: count="..(m.knockbacks or 0).." distance="..distance)
   return .05
  end
  return .05
 end)
 if not ok then log("ERROR "..tostring(result));cleanup();return nil end
 return result
end,.05)
