-- Explicit native VFX exercise only; accelerated attacks are not a balance test.
-- Console: script_reload_code rift/dev/sven_visual
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local lab=gm.lab;lab:Clear();lab.rank=3
assert(lab:Select("npc_dota_hero_sven","physical"))
local ready,c,u,deadline
GameRules:GetGameModeEntity():SetContextThink("rift_sven_visual",function()
 local now=GameRules:GetGameTime()
 if lab.loading then return .1 end
 if not ready then ready=now+.7;return .1 end
 if now<ready then return .1 end
 if not c then
  c=PlayerResource:GetSelectedHeroEntity(lab.owner);c:Stop();c:SetForwardVector(Vector(1,0,0))
  assert(lab:Target("immortal"));u=lab.targets[1]
  FindClearSpaceForUnit(u,c:GetAbsOrigin()+Vector(180,0,0),true)
  deadline=now+25
 end
 if now>=deadline or c:IsNull() or not c:IsAlive() or u:IsNull() then
  print("[RIFT][VISUAL] Sven exercise finished");return nil
 end
 if not c:HasModifier("modifier_rift_path_stance") then
  local a=c:FindAbilityByName("rift_sven_physical");a:EndCooldown();c:GiveMana(a:GetManaCost(-1))
  c:CastAbilityNoTarget(a,lab.owner);return .6
 end
 c:PerformAttack(u,true,true,true,true,false,false,true)
 return .3
end,.1)
