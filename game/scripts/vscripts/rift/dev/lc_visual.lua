-- Bounded visual exercise: stone remnant and compact arrows. Lab only.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local lab=gm.lab;lab:Clear();lab.rank=3
assert(lab:Select("npc_dota_hero_legion_commander","magical"))
local ready,c,u,deadline,next_cast
GameRules:GetGameModeEntity():SetContextThink("rift_lc_visual",function()
 local now=GameRules:GetGameTime()
 if lab.loading then return .1 end
 if not ready then ready=now+.7;return .1 end
 if now<ready then return .1 end
 if not c then
  c=PlayerResource:GetSelectedHeroEntity(lab.owner);c:Stop();c:SetForwardVector(Vector(1,0,0))
  assert(lab:Target("immortal"));u=lab.targets[1]
  FindClearSpaceForUnit(u,c:GetAbsOrigin()+Vector(450,0,0),true)
  deadline=now+25;next_cast=0
 end
 if now>=deadline or c:IsNull() or not c:IsAlive() or u:IsNull() then return nil end
 if now>=next_cast then
  local a=c:FindAbilityByName("lc_statue");a:EndCooldown();c:GiveMana(a:GetManaCost(-1))
  c:CastAbilityOnPosition(c:GetAbsOrigin()+Vector(200,0,0),a,lab.owner)
  next_cast=now+3
 end
 return .1
end,.1)
