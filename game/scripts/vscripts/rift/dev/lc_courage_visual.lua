-- Explicit single-player hot refresh + bounded visual exercise, no duplicated balance values.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local key="rift.data.hero_balance"
local old=require(key);package.loaded[key]=nil;local fresh=require(key)
for _,name in ipairs({"duel_physical","courage_physical"})do
 for k,v in pairs(fresh.lc[name])do old.lc[name][k]=v end
end
package.loaded[key]=old
package.loaded["rift.modifiers.modifier_rift_lc_courage"]=nil
require("rift.modifiers.modifier_rift_lc_courage")
local lab=gm.lab;lab:Clear();lab.rank=3
assert(lab:Select("npc_dota_hero_legion_commander","physical"))
local ready,c,u,deadline,next_hit,initial_heal
GameRules:GetGameModeEntity():SetContextThink("rift_lc_courage_visual",function()
 local now=GameRules:GetGameTime()
 if lab.loading then return .1 end
 if not ready then ready=now+.7;return .1 end
 if now<ready then return .1 end
 if not c then
  c=PlayerResource:GetSelectedHeroEntity(lab.owner);c:Stop();c:SetForwardVector(Vector(1,0,0))
  assert(lab:Target("immortal"));u=lab.targets[1]
  FindClearSpaceForUnit(u,c:GetAbsOrigin()+Vector(130,0,0),true)
  c:SetHealth(math.floor(c:GetMaxHealth()/2));initial_heal=c:GetHealth()
  local a=c:FindAbilityByName("lc_duel_physical")
  for rank=1,3 do a:SetLevel(rank);print("[RIFT][COURAGE] R"..rank.." cooldown="..a:GetCooldown(-1).." per_second="..old.lc.duel_physical.per_second[rank])end
  a:SetLevel(3);deadline=now+120;next_hit=0
 end
 if c:IsNull() or PlayerResource:GetSelectedHeroEntity(lab.owner)~=c or not c:IsAlive() or u:IsNull() then return nil end
 if now>=deadline then
  print("[RIFT][COURAGE] DONE health_delta="..(c:GetHealth()-initial_heal));return nil
 end
 if now>=next_hit then
  for _=1,old.lc.courage_physical.attacks[4]do c:PerformAttack(u,true,true,false,false,false,false,true)end
  next_hit=now+.2
 end
 return .1
end,.1)
