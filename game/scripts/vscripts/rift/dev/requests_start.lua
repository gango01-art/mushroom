-- Explicit, single-player native validation. Never loaded by normal gameplay.
-- Console: script_reload_code rift/dev/requests_start
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local lab=gm.lab;lab.free=false
local previous_verbose=require("rift.engine.log").verbose
require("rift.engine.log").verbose=true
local function log(s)print("[RIFT][REQUESTS] "..s)end
local function souls(c)return c:FindModifierByName("modifier_nevermore_necromastery"):GetStackCount()end
local soul_service=require("rift.engine.sf_souls")
local original_death=soul_service.on_death
soul_service.on_death=function(c)
 if c and not c:IsNull() and c:GetUnitName()=="npc_dota_hero_nevermore" then
  log("SF death event alive="..tostring(c:IsAlive()).." reincarnating="..tostring(c:IsReincarnating()).." illusion="..tostring(c:IsIllusion()))
 end
 original_death(c)
end
local cases={
 {hero="sf",path="physical",run=function(c,u,v)
  local m=c:FindModifierByName("modifier_nevermore_necromastery");m:SetStackCount(0)
  c:PerformAttack(u,true,true,true,true,false,false,true)
  log("SF attack souls="..souls(c).." expected=1")
  c:CastAbilityNoTarget(c:FindAbilityByName("nevermore_shadowraze1"),lab.owner)
  return function()
   log("SF two-target raze souls="..souls(c).." expected=3 raze_cd="..c:FindAbilityByName("nevermore_shadowraze1"):GetCooldownTimeRemaining())
   ApplyDamage({victim=u,attacker=c,ability=c:FindAbilityByName("sf_requiem_physical"),damage=1000000,damage_type=DAMAGE_TYPE_PURE})
   log("SF kill souls="..souls(c).." expected=3")
   m:SetStackCount(10);c:ForceKill(false);log("SF ForceKill alive="..tostring(c:IsAlive()))
   return function()return "SF death souls="..souls(c).." expected=7" end,.3
  end,.8
 end},
 {hero="sf",path="magical",run=function(c,u,v)
  local m=c:FindModifierByName("modifier_nevermore_necromastery");m:SetStackCount(0)
  local p=c:GetAbsOrigin();FindClearSpaceForUnit(u,p+Vector(300,0,0),true);FindClearSpaceForUnit(v,p+Vector(500,0,0),true)
  -- Keep targets fixed so fear does not move them out of the next ring.
  u:AddNewModifier(c,nil,"modifier_rift_path_root",{duration=6});v:AddNewModifier(c,nil,"modifier_rift_path_root",{duration=6})
  c:CastAbilityNoTarget(c:FindAbilityByName("nevermore_requiem"),lab.owner)
  return function()
   local a=u:FindModifierByName("modifier_nevermore_shadowraze_debuff")
   local b=v:FindModifierByName("modifier_nevermore_shadowraze_debuff")
   return "SF rings souls="..souls(c).." stacks="..tostring(a and a:GetStackCount())..","..tostring(b and b:GetStackCount())
  end,4.2
 end},
 {hero="pa",path="magical",run=function(c,u,v)
  local item=CreateItem("item_desolator",c,c);c:AddItem(item)
  local a=c:FindAbilityByName("pa_storm_dagger");local before=u:GetHealth()+v:GetHealth()
  c:CastAbilityOnTarget(u,a,lab.owner)
  return function()
   local mods={};for i=0,u:GetModifierCount()-1 do mods[#mods+1]=u:GetModifierNameByIndex(i) end
   return string.format("PA dagger damage=%.1f expected_two_targets mods=%s",before-u:GetHealth()-v:GetHealth(),table.concat(mods,","))
  end,2
 end},
 {hero="cm",path="physical",run=function(c,u,v)
  local p=c:GetAbsOrigin();FindClearSpaceForUnit(u,p+Vector(300,0,0),true);FindClearSpaceForUnit(v,p-Vector(300,0,0),true)
  local hu,hv=u:GetHealth(),v:GetHealth()
  c:CastAbilityNoTarget(c:FindAbilityByName("rift_cm_physical"),lab.owner)
  return function()return string.format("CM front_damage=%.1f behind_damage=%.1f",hu-u:GetHealth(),hv-v:GetHealth())end,3
 end},
 {hero="lc",path="physical",run=function(c,u)
  c:AddItem(CreateItem("item_echo_sabre",c,c));c:AddItem(CreateItem("item_hyperstone",c,c))
  c:AddItem(CreateItem("item_pipe",c,c))
  local before=c:GetAttacksPerSecond(false);c:PerformAttack(u,true,true,true,true,false,false,true)
  local aps,stable=c:GetAttacksPerSecond(false),c:GetAttacksPerSecond(true)
   log(string.format("LC Echo APS before=%.3f temporary=%.3f ignore_temporary=%.3f MR=%.3f evasion=%.3f",before,aps,stable,c:Script_GetMagicalArmorValue(nil),c:GetEvasion()))
  local a=c:FindAbilityByName("lc_duel_physical");c:CastAbilityOnTarget(u,a,lab.owner)
  return function()
   local s=require("rift.engine.lc_duel_session").sessions[lab.owner]
   assert(s,"LC duel did not start")
   local m=c:FindModifierByName("modifier_rift_lc_throne")
   log(string.format("LC champion APS=%.3f expected=%.3f MR=%.3f armor=%.1f elevated_z=%.1f courage=%s",s.champion:GetAttacksPerSecond(false),stable*.9,s.champion:Script_GetMagicalArmorValue(nil),s.champion:GetPhysicalArmorValue(false),c:GetAbsOrigin().z-s.throne.z,tostring(c:FindAbilityByName("rift_lc_courage")~=nil)))
   s.champion:ForceKill(false)
   return function()return "LC champion death cyclone_removed="..tostring(not c:HasModifier("modifier_rift_lc_throne")) end,.5
  end,.8
 end},
 {hero="lina",path="physical",run=function(c,u,v)
  local a=c:FindAbilityByName("rift_lina_physical");local before=u:GetHealth()+v:GetHealth()
  log(string.format("Lina attack=%.1f AS=%.1f expected_wave_raw=%.1f burn=%.1f",c:GetAverageTrueAttackDamage(nil),c:GetDisplayAttackSpeed(),require("rift.core.path_math").damage(require("rift.data.expansion").abilities.rift_lina_physical,3,require("rift.engine.path_combat").snapshot(c)),c:FindAbilityByName("lina_slow_burn"):GetSpecialValueFor("burn_damage_pct")))
  c:CastAbilityOnPosition(u:GetAbsOrigin(),a,lab.owner)
  return function()return string.format("Lina piercing_wave_damage=%.1f cooldown=%.1f",before-u:GetHealth()-v:GetHealth(),a:GetCooldownTimeRemaining()) end,3
 end},
}
local i,phase,deadline,report,at,ready_at=0,"next",0
local function step()
 local now=GameRules:GetGameTime()
 if phase=="next" then
  i=i+1;if not cases[i] then soul_service.on_death=original_death;require("rift.engine.log").verbose=previous_verbose;log("DONE");return nil end
  local aliases={sf="nevermore",pa="phantom_assassin",lc="legion_commander",cm="crystal_maiden"}
  local hero="npc_dota_hero_"..(aliases[cases[i].hero] or cases[i].hero)
  lab:Clear();lab.rank=3;assert(lab:Select(hero,cases[i].path));phase="load";deadline=now+40;ready_at=nil
 elseif phase=="load" then
  assert(now<deadline,"load timeout")
  if lab.loading then return .1 end
  if not ready_at then ready_at=now+.6;return .1 end
  if now<ready_at then return .1 end
  local c=PlayerResource:GetSelectedHeroEntity(lab.owner);c:Stop();c:SetForwardVector(Vector(1,0,0))
  assert(lab:Target("mortal"));assert(lab:Target("mortal"))
  local u,v=lab.targets[1],lab.targets[2]
  for k,x in ipairs({u,v}) do
   x:SetBaseMaxHealth(50000);x:CalculateStatBonus(true);x:SetHealth(x:GetMaxHealth())
   FindClearSpaceForUnit(x,c:GetAbsOrigin()+Vector(200,(k-1)*55,0),true)
  end
  report,at=cases[i].run(c,u,v);at=now+at;phase="report"
 elseif phase=="report" and now>=at then
  local result,delay=report()
  if type(result)=="function" then report=result;at=now+delay
  else log(result);phase="next" end
 end
 return .1
end
GameRules:GetGameModeEntity():SetContextThink("rift_requests_probe",function()
 local ok,result=pcall(step)
 if not ok then soul_service.on_death=original_death;require("rift.engine.log").verbose=previous_verbose;log("ERROR "..tostring(result));return nil end
 return result
end,.1)
