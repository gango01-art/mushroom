-- Bounded native visual exercise: TA shield, Lina impact, then LC statue.
-- Console: script_reload_code rift/dev/revision_visual (single-player lab only).
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local lab=gm.lab
local scenes={
 {hero="templar_assassin",ability="ta_refraction_magical",seconds=20},
 {hero="lina",ability="rift_lina_magical",seconds=20,point=true},
 {hero="legion_commander",ability="lc_statue",seconds=25,point=true},
}
local i,phase,ready,deadline,next_cast,c,u=0,"next"
GameRules:GetGameModeEntity():SetContextThink("rift_revision_visual",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime()
  if phase=="next"then
   i=i+1;if not scenes[i]then print("[RIFT][VISUAL] DONE");return nil end
   lab:Clear();lab.rank=3;assert(lab:Select("npc_dota_hero_"..scenes[i].hero,"magical"))
   phase="load";ready=nil;deadline=now+40
  elseif phase=="load"then
   assert(now<deadline,"hero load timeout")
   if lab.loading then return .1 end
   if not ready then ready=now+.7;return .1 end
   if now<ready then return .1 end
   c=PlayerResource:GetSelectedHeroEntity(lab.owner);c:Stop();c:SetForwardVector(Vector(1,0,0))
   assert(lab:Target("immortal"));u=lab.targets[1]
   FindClearSpaceForUnit(u,c:GetAbsOrigin()+Vector(450,0,0),true)
   deadline=now+scenes[i].seconds;next_cast=0;phase="show"
   print("[RIFT][VISUAL] "..scenes[i].hero)
  elseif phase=="show"then
   if now>=deadline then phase="next";return .1 end
   if now>=next_cast then
    local a=c:FindAbilityByName(scenes[i].ability);a:EndCooldown();c:GiveMana(a:GetManaCost(-1))
    if scenes[i].point then c:CastAbilityOnPosition(c:GetAbsOrigin()+Vector(200,0,0),a,lab.owner)
    else c:CastAbilityNoTarget(a,lab.owner)end
    next_cast=now+3
   end
  end
  return .1
 end)
 if not ok then print("[RIFT][VISUAL] ERROR "..tostring(result));return nil end
 return result
end,.1)
