-- Console: script_reload_code rift/dev/mechanics_start (single-player lab only).
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player laboratory required")
local lab=gm.lab
lab.free=false
local cases={
 {hero="juggernaut",path="physical",run=function(c,u)
   local a=c:FindAbilityByName("rift_juggernaut_physical");a:StartCooldown(30)
   c:PerformAttack(u,true,true,true,true,false,false,true)
   return function()return string.format("one_attack_cd=%.2f expected_about_27.7",a:GetCooldownTimeRemaining())end,.3
 end},
 {hero="juggernaut",path="magical",run=function(c,u)
   local a=c:FindAbilityByName("rift_juggernaut_magical")
   u:SetBaseMagicalResistanceValue(0)
   local lo,hi,procs=100000,0,0
   for _=1,100 do
     u:SetHealth(u:GetMaxHealth())
     local hp=u:GetHealth()
     ApplyDamage({victim=u,attacker=c,ability=a,damage=100,damage_type=DAMAGE_TYPE_MAGICAL})
     -- ApplyDamage's return value precedes the damage filter in this build.
     -- Actual HP loss reflects the final event including the critical multiplier.
     local dealt=hp-u:GetHealth()
     lo=math.min(lo,dealt);hi=math.max(hi,dealt);if dealt>110 then procs=procs+1 end
   end
   print(string.format("[RIFT][MECHANICS] magic_crit min=%.2f max=%.2f procs=%d/100",lo,hi,procs))
   c:CastAbilityNoTarget(a,lab.owner)
   return function()
     c:ForceKill(false);u:SetHealth(u:GetMaxHealth());local before=u:GetHealth()
     return function()return string.format("storm_after_death_damage=%.1f",before-u:GetHealth())end,2
   end,1
 end},
 {hero="sven",path="physical",run=function(c,u)
   local a=c:FindAbilityByName("rift_sven_echo");local hp=u:GetHealth()
   c:PerformAttack(u,true,true,true,true,false,false,true)
   return function()return string.format("echo_cd=%.2f damage_two_hits=%.1f",a:GetCooldownTimeRemaining(),hp-u:GetHealth())end,.4
 end},
 {hero="sven",path="magical",run=function(c,u)
   local a=c:FindAbilityByName("rift_sven_magical")
   local m=u:AddNewModifier(c,a,"modifier_rift_path_root",{duration=10})
   local duration=m:GetDuration();u:RemoveModifierByName("modifier_rift_path_root")
   print("[RIFT][MECHANICS] raw_lua_modifier_duration="..duration.." base=10 caster_amp=16")
   c:CastAbilityOnPosition(u:GetAbsOrigin(),a,lab.owner)
   return function()
     local stun=u:FindModifierByName("modifier_stunned")
     return "custom_stun_duration="..tostring(stun and stun:GetDuration()).." base=.75 expected=.87"
   end,1.2
 end},
 {hero="axe",path="physical",run=function(c,u)
   local a=c:FindAbilityByName("rift_axe_physical")
   local p=c:GetAbsOrigin();FindClearSpaceForUnit(u,p+Vector(445,0,0),true)
   local item=CreateItem("item_shivas_guard",c,c);c:AddItem(item)
   local before=u:GetHealth();c:CastAbilityNoTarget(a,lab.owner)
   return function()return string.format("shiva_boundary_damage=%.1f base_radius=425 target_distance=445 expanded=%.1f",before-u:GetHealth(),a:GetAOERadius())end,1
 end},
 {hero="pa",path="physical",run=function(c,u)
   local a=c:FindAbilityByName("pa_phantom_execution");a:StartCooldown(20)
   c:CastAbilityOnTarget(u,c:FindAbilityByName("phantom_assassin_stifling_dagger"),lab.owner)
   return function()return string.format("dagger_ult_cd=%.2f expected_about_16.7",a:GetCooldownTimeRemaining())end,1.3
 end},
}
for rank=1,3 do
 local r=rank
 cases[#cases+1]={hero="wr",path="physical",rank=r,run=function(c)
  local a=c:FindAbilityByName("rift_wr_physical");local before=c:GetAttacksPerSecond(false)
  c:CastAbilityNoTarget(a,lab.owner)
  return function()
   local m=c:FindModifierByName("modifier_rift_path_stance")
   return string.format("rank=%d bonus_attack_speed=%s APS_before=%.3f APS_after=%.3f cooldown=%.2f",r,
    tostring(m and m:GetModifierAttackSpeedBonus_Constant()),before,c:GetAttacksPerSecond(false),a:GetCooldownTimeRemaining())
  end,1
 end}
end
local i,phase,at,report,c,u=0,"next",0
local function step()
 local now=GameRules:GetGameTime()
 if phase=="next" then
   i=i+1;if not cases[i] then print("[RIFT][MECHANICS] DONE");return nil end
   lab:Clear();lab.rank=cases[i].rank or 3
   local hero=require("rift.core.laboratory").resolve_hero(cases[i].hero,lab.known)
   assert(lab:Select(hero,cases[i].path));phase="loading"
 elseif phase=="loading" then
   if lab.loading then return .1 end
   c=PlayerResource:GetSelectedHeroEntity(lab.owner);c:Stop();c:SetForwardVector(Vector(1,0,0))
   assert(lab:Target("immortal"));u=lab.targets[1];FindClearSpaceForUnit(u,c:GetAbsOrigin()+Vector(150,0,0),true)
   report,at=cases[i].run(c,u);at=now+at;phase="report"
 elseif phase=="report" and now>=at then
   local result,delay=report()
   if type(result)=="function" then report=result;at=now+delay
   else print("[RIFT][MECHANICS] "..cases[i].hero.." "..cases[i].path.." "..result);phase="next" end
 end
 return .1
end
GameRules:GetGameModeEntity():SetContextThink("rift_mechanics_probe",function()
 local ok,result=pcall(step)
 if not ok then print("[RIFT][MECHANICS] ERROR "..tostring(result));return nil end
 return result
end,.1)
