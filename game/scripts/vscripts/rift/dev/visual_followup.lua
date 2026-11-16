-- Explicit single-player visual exercise; hot-refreshes installed data without
-- duplicating balance constants. Forced attacks/cooldown resets are test-only.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local key="rift.data.hero_balance";local old=require(key);package.loaded[key]=nil;local fresh=require(key)
local function merge(to,from)
 for k,v in pairs(from)do if type(v)=="table"and type(to[k])=="table"then merge(to[k],v)else to[k]=v end end
end
merge(old,fresh);package.loaded[key]=old
for _,name in ipairs({"modifier_rift_lc_courage","modifier_rift_sven_echo","modifier_rift_sf_spheres","modifier_rift_ta_meld"})do
 local path="rift.modifiers."..name;package.loaded[path]=nil;require(path)
end
local lab=gm.lab;lab:Clear()
local scenes={"nevermore","templar_assassin","sven","legion_commander"}
local i,phase,c,u,ready,deadline,next_action,started,step=0,"next"
GameRules:GetGameModeEntity():SetContextThink("rift_visual_followup",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime()
  if phase=="next"then
   i=i+1;if not scenes[i]then print("[RIFT][FOLLOWUP] DONE");return nil end
   lab:Clear();lab.rank=3;assert(lab:Select("npc_dota_hero_"..scenes[i],"physical"))
   phase="load";ready=nil;deadline=now+40
  elseif phase=="load"then
   assert(now<deadline,"precache timeout")
   if lab.loading then return .1 end
   if not ready then ready=now+.7;return .1 end
   if now<ready then return .1 end
   c=PlayerResource:GetSelectedHeroEntity(lab.owner);c:Stop();c:SetForwardVector(Vector(1,0,0))
   assert(lab:Target("immortal"));u=lab.targets[1]
   FindClearSpaceForUnit(u,c:GetAbsOrigin()+Vector(scenes[i]=="nevermore" and 450 or 130,0,0),true)
   c:SetHealth(math.floor(c:GetMaxHealth()/2));started=now;deadline=now+60;next_action=0;step=0;phase="show"
   print("[RIFT][FOLLOWUP] "..scenes[i])
   if scenes[i]=="sven" then c:CastAbilityNoTarget(c:FindAbilityByName("rift_sven_physical"),lab.owner);next_action=now+.6 end
  elseif phase=="show"then
   if now>=deadline then phase="next";return .1 end
   if now>=next_action then
    step=step+1
    if scenes[i]=="legion_commander" then
     c:Stop()
     for _=1,old.lc.courage_physical.attacks[4]do c:PerformAttack(u,true,true,false,true,false,false,true)end
     next_action=now+1.5
    elseif scenes[i]=="sven" then
     if step%3==0 then
      local a=c:FindAbilityByName("sven_storm_bolt");a:EndCooldown();c:GiveMana(a:GetManaCost(-1));c:CastAbilityOnTarget(u,a,lab.owner)
     elseif step%3==1 then c:MoveToTargetToAttack(u)
     else
      local a=c:FindAbilityByName("sven_warcry");a:EndCooldown();c:GiveMana(a:GetManaCost(-1));c:CastAbilityNoTarget(a,lab.owner)
     end
     next_action=now+3
    elseif scenes[i]=="nevermore" then
     if step==1 or not c:HasModifier("modifier_rift_sf_spheres")then
      c:Stop();local a=c:FindAbilityByName("sf_requiem_physical");a:EndCooldown();c:GiveMana(a:GetManaCost(-1));c:CastAbilityNoTarget(a,lab.owner)
      next_action=now+8
     else c:PerformAttack(u,true,true,false,true,false,false,true);next_action=now+.7 end
    else
     if step%2==1 then
      c:Stop();local a=c:FindAbilityByName("ta_meld_physical");a:EndCooldown();c:GiveMana(a:GetManaCost(-1));c:CastAbilityNoTarget(a,lab.owner)
      next_action=now+1.5
     else c:MoveToTargetToAttack(u);next_action=now+1.5 end
    end
   end
  end
  return .1
 end)
 if not ok then print("[RIFT][FOLLOWUP] ERROR "..tostring(result));return nil end
 return result
end,.1)
