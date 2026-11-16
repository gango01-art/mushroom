-- Explicit native cast checks beyond data resolution. No normal-game autoload.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local lab=gm.lab;lab:Clear()
local scenes={{"nevermore","physical","sf_requiem_physical"},{"templar_assassin","physical","ta_psionic_crystal"},{"templar_assassin","magical","ta_refraction_magical"}}
local i,phase,deadline,c,a,point=0,"next"
GameRules:GetGameModeEntity():SetContextThink("rift_progression_effects",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime()
  if phase=="next"then
   i=i+1;if not scenes[i]then print("[RIFT][PROGRESSION_CAST] DONE 3/3");return nil end
   lab:Clear();lab.rank=3;assert(lab:Select("npc_dota_hero_"..scenes[i][1],scenes[i][2]))
   phase="load";deadline=now+40
  elseif phase=="load"then
   assert(now<deadline,"precache timeout");if lab.loading then return .1 end
   c=PlayerResource:GetSelectedHeroEntity(lab.owner);a=c:FindAbilityByName(scenes[i][3]);assert(a,"ability missing")
   c:AddItemByName("item_ultimate_scepter");local shard=c:AddItemByName("item_aghanims_shard")
   if shard and not shard:IsNull()and not c:HasModifier("modifier_item_aghanims_shard")then c:CastAbilityNoTarget(shard,lab.owner)end
   deadline=now+5;phase="cast"
  elseif phase=="cast"then
   if not c:HasScepter()or not c:HasModifier("modifier_item_aghanims_shard")then assert(now<deadline,"native items missing");return .1 end
   point=c:GetAbsOrigin()+c:GetForwardVector()*150
   if i==2 then c:CastAbilityOnPosition(point,a,lab.owner)else c:CastAbilityNoTarget(a,lab.owner)end
   phase="check";deadline=now+3
  elseif phase=="check"then
   if i==1 then
    local m=c:FindModifierByName("modifier_rift_sf_spheres")
    if not m then assert(now<deadline,"sphere modifier missing");return .1 end
    assert(m:GetRemainingTime()>17 and m:GetRemainingTime()<=18.1,"SF duration")
    assert(math.abs(m.session:regen_time()-1.2)<.001,"SF regen")
    print(string.format("[RIFT][PROGRESSION_CAST] SF duration=%.2f regen=%.2f",m:GetRemainingTime(),m.session:regen_time()))
   elseif i==2 then
    local crystal=a.crystal
    if not crystal or crystal:IsNull()then assert(now<deadline,"crystal missing");return .1 end
    local m=crystal:FindModifierByName("modifier_rift_ta_crystal")
    assert(crystal:GetMaxHealth()==5,"crystal durability")
    assert(math.abs(m.radius-520)<.001,"crystal radius")
    print("[RIFT][PROGRESSION_CAST] TA crystal durability="..crystal:GetMaxHealth().." radius="..m.radius)
   else
    local m=c:FindModifierByName("modifier_rift_ta_refraction")
    if not m then assert(now<deadline,"shield missing");return .1 end
    assert(m:GetStackCount()==8,"Refraction charges")
    print("[RIFT][PROGRESSION_CAST] TA shield charges="..m:GetStackCount())
   end
   phase="wait";deadline=now+3
  elseif phase=="wait"and now>=deadline then phase="next"end
  return .1
 end)
 if not ok then print("[RIFT][PROGRESSION_CAST] ERROR scene="..i.." "..tostring(result));return nil end
 return result
end,.1)
