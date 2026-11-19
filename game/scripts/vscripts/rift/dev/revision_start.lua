-- Native checks for the second owner playtest revision. Single-player only.
-- Console: script_reload_code rift/dev/revision_start
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local lab=gm.lab;lab.free=false
local function log(s)print("[RIFT][REVISION] "..s)end
local cases={
 {hero="crystal_maiden",path="physical",run=function(c,u)
  c:SetBaseManaRegen(25)
  local a=c:FindAbilityByName("rift_cm_physical");local hp=u:GetHealth()
  local stats=require("rift.engine.path_combat").snapshot(c)
  log(string.format("CM regen=%.2f attack=%.1f wave_raw=%.2f",stats.mana_regen,stats.attack,
   require("rift.core.path_math").damage(require("rift.data.expansion").abilities.rift_cm_physical,3,stats)))
  c:CastAbilityNoTarget(a,lab.owner)
  return function()return "CM damage="..(hp-u:GetHealth())end,2.2
 end},
 {hero="juggernaut",path="physical",run=function(c,u)
  local a=c:FindAbilityByName("rift_juggernaut_physical");a:StartCooldown(20)
  c:PerformAttack(u,true,true,false,true,false,false,true)
  return function()
   log("Jug ordinary cd="..a:GetCooldownTimeRemaining().." expected_about=19.7")
   c:Stop();a:EndCooldown();c:CastAbilityOnPosition(u:GetAbsOrigin(),a,lab.owner)
   return function()return "Jug series cd="..a:GetCooldownTimeRemaining().." expected_about=25 (two enemies, 2s each hit)"end,1
  end,.2
 end},
 {hero="phantom_assassin",path="physical",run=function(c,u)
  local a=c:FindAbilityByName("pa_phantom_execution");a:StartCooldown(20)
  c:PerformAttack(u,true,true,false,true,false,false,true)
  return function()
   log("PA ordinary cd="..a:GetCooldownTimeRemaining().." expected_about=18.8")
   c:Stop();a:StartCooldown(20);c:CastAbilityOnTarget(u,c:FindAbilityByName("phantom_assassin_stifling_dagger"),lab.owner)
   return function()return "PA dagger cd="..a:GetCooldownTimeRemaining().." expected_about=17"end,1
  end,.2
 end},
 {hero="phantom_assassin",path="magical",run=function(c,u)
  assert(lab:Target("immortal"));assert(lab:Target("immortal"))
  for i,x in ipairs(lab.targets) do FindClearSpaceForUnit(x,c:GetAbsOrigin()+Vector(800,(i-1)*50,0),true) end
  c:CastAbilityOnTarget(u,c:FindAbilityByName("pa_storm_dagger"),lab.owner)
  return function()
   local ctx;for _,x in pairs(require("rift.engine.pa_storm").store().contexts) do if x.caster==c:entindex()then ctx=x end end
   log("PA crowd targets="..tostring(ctx and #ctx.targets).." expected=2")
   local a=c:FindAbilityByName("pa_storm_dagger");local before=0
   for _,x in ipairs(lab.targets)do before=before+x:GetHealth()end
   require("rift.engine.pa_storm").store().force_proc=true
   a:EndCooldown();c:CastAbilityOnTarget(u,a,lab.owner)
   return function()
    require("rift.engine.pa_storm").store().force_proc=nil
    local after=0;for _,x in ipairs(lab.targets)do after=after+x:GetHealth()end
    return "PA two-target forced chain damage="..(before-after)
   end,1.4
  end,.6
 end},
 {hero="sven",path="magical",run=function(c)
  return function()return "Sven R3 base cooldown="..c:FindAbilityByName("rift_sven_magical"):GetCooldown(-1).." expected=35"end,.1
 end},
 {hero="templar_assassin",path="magical",run=function(c)
  c:CastAbilityNoTarget(c:FindAbilityByName("ta_refraction_magical"),lab.owner)
  return function()
   local m=c:FindModifierByName("modifier_rift_ta_refraction")
   return "TA shield="..tostring(m~=nil).." charges="..tostring(m and m:GetStackCount())
  end,1
 end},
 {hero="legion_commander",path="magical",run=function(c,u)
  c:CastAbilityOnPosition(u:GetAbsOrigin(),c:FindAbilityByName("lc_statue"),lab.owner)
  return function()
   local s=require("rift.engine.lc_magic").statues[lab.owner]
   return "LC statue model="..tostring(s and s.unit:GetModelName())
  end,1
 end},
}
for rank=1,3 do
 local r=rank
 table.insert(cases,5,{hero="windrunner",path="physical",rank=r,run=function(c)
  c:CastAbilityNoTarget(c:FindAbilityByName("rift_wr_physical"),lab.owner)
  return function()
   local m=c:FindModifierByName("modifier_rift_path_stance")
   return "WR rank="..r.." duration="..tostring(m and m:GetDuration())
  end,.6
 end})
end
local i,phase,ready,deadline,report,at=0,"next"
GameRules:GetGameModeEntity():SetContextThink("rift_revision_probe",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime()
  if phase=="next"then
   i=i+1;if not cases[i]then log("DONE");return nil end
   lab:Clear();lab.rank=cases[i].rank or 3
   assert(lab:Select("npc_dota_hero_"..cases[i].hero,cases[i].path));phase="load";ready=nil;deadline=now+40
  elseif phase=="load"then
   assert(now<deadline,"hero load timeout")
   if lab.loading then return .1 end
   if not ready then ready=now+.7;return .1 end
   if now<ready then return .1 end
   local c=PlayerResource:GetSelectedHeroEntity(lab.owner);c:Stop();c:SetForwardVector(Vector(1,0,0))
   assert(lab:Target("immortal"));assert(lab:Target("immortal"))
   for k,x in ipairs(lab.targets)do
    x:SetBaseMaxHealth(50000);x:CalculateStatBonus(true);x:SetHealth(x:GetMaxHealth())
    FindClearSpaceForUnit(x,c:GetAbsOrigin()+Vector(200,(k-1)*60,0),true)
   end
   report,at=cases[i].run(c,lab.targets[1]);at=now+at;phase="report"
  elseif phase=="report"and now>=at then
   local text,delay=report()
   if type(text)=="function"then report=text;at=now+delay else log(text);phase="next"end
  end
  return .1
 end)
 if not ok then require("rift.engine.pa_storm").store().force_proc=nil;log("ERROR "..tostring(result));return nil end
 return result
end,.1)
