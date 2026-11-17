-- Real casts for the three retained common Shards, both paths. Tools only.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local lab=gm.lab;lab:Clear();lab.free=false
local cases={};for _,h in ipairs({"axe","legion_commander","nevermore"})do for _,p in ipairs({"physical","magical"})do cases[#cases+1]={h=h,p=p}end end
local i,phase,c,a,u,v,deadline=0,"next"
GameRules:GetGameModeEntity():SetContextThink("rift_hybrid_shard_probe",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime()
  if phase=="next"then
   i=i+1;if not cases[i]then print("[RIFT][HYBRID] DONE 6/6");return nil end
   lab:Clear();assert(lab:Select("npc_dota_hero_"..cases[i].h,cases[i].p));phase="load";deadline=now+40
  elseif phase=="load"then
   assert(now<deadline,"hero timeout");if lab.loading then return .1 end
   c=PlayerResource:GetSelectedHeroEntity(lab.owner);c:Stop();c:SetForwardVector(Vector(1,0,0))
   c:AddItemByName("item_aghanims_shard");phase="shard";deadline=now+5
  elseif phase=="shard"then
   if not c:HasModifier("modifier_item_aghanims_shard")then assert(now<deadline,"native shared Shard missing");return .1 end
   assert(lab:Target("immortal"));assert(lab:Target("immortal"));u,v=lab.targets[1],lab.targets[2]
   for n,t in ipairs({u,v})do t:SetBaseMaxHealth(10000);t:SetHealth(t:GetMaxHealth());FindClearSpaceForUnit(t,c:GetAbsOrigin()+Vector(200,(n-1)*65,0),true)end
   local names={axe="axe_berserkers_call",legion_commander="legion_commander_overwhelming_odds",nevermore="nevermore_shadowraze1"}
   a=assert(c:FindAbilityByName(names[cases[i].h]));a:EndCooldown();c:CastAbilityNoTarget(a,lab.owner);deadline=now+1;phase="cast"
  elseif phase=="cast"then
   if now<deadline then return .05 end
   local h=cases[i].h
   if h=="axe"then
    assert(u:HasModifier("modifier_axe_battle_hunger")and v:HasModifier("modifier_axe_battle_hunger"),"Call did not apply Hunger")
    print("[RIFT][HYBRID] PASS axe "..cases[i].p.." Call applied Hunger to both heroes")
   elseif h=="legion_commander"then
    local hp=c:GetHealth();ApplyDamage({victim=c,attacker=u,damage=100,damage_type=DAMAGE_TYPE_PURE})
    assert(c:GetHealth()==hp,"Odds barrier failed to absorb pure damage")
    assert(a:GetSpecialValueFor("radius")==700,"Odds Shard radius")
    print("[RIFT][HYBRID] PASS legion_commander "..cases[i].p.." radius=700 barrier absorbed 100 pure")
   else
    assert(u:HasModifier("modifier_nevermore_shadowraze_debuff")and v:HasModifier("modifier_nevermore_shadowraze_debuff"),"raze missed")
    local cd=a:GetCooldownTimeRemaining();assert(cd<5.5,"raze Shard did not reduce cooldown for two heroes: "..cd)
    assert(a:GetSpecialValueFor("movement_speed_debuff")==12,"raze Shard slow")
    print("[RIFT][HYBRID] PASS nevermore "..cases[i].p.." two hero hits cooldown="..cd.." slow=12 per stack")
   end
   phase="next"
  end
  return .1
 end)
 if not ok then print("[RIFT][HYBRID] ERROR case="..i.." "..tostring(result));return nil end
 return result
end,.1)

