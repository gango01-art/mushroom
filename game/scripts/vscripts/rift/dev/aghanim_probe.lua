-- Explicit single-player Tools probe; not PvP balance proof.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local A=require("rift.engine.aghanim");local P=require("rift.engine.progression")
local B=require("rift.data.hero_balance").progression
local cases={};for h in pairs(B.heroes)do for _,p in ipairs({"physical","magical"})do cases[#cases+1]={hero=h,path=p}end end
table.sort(cases,function(a,b)return a.hero==b.hero and a.path>b.path or a.hero<b.hero end)
local lab=gm.lab;lab:Clear();lab.free=false
local i,phase,c,deadline,item=0,"next"
GameRules:GetGameModeEntity():SetContextThink("rift_aghanim_probe",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime()
  if phase=="next"then
   i=i+1
   if not cases[i]then print("[RIFT][AGHANIM] DONE 22/22; TA innate follow-up");lab:Select("npc_dota_hero_templar_assassin","physical");phase="ta_load";deadline=now+40;return .1 end
   lab:Clear();assert(lab:Select(cases[i].hero,cases[i].path));phase="load";deadline=now+40
  elseif phase=="load"then
   assert(now<deadline,"hero timeout");if lab.loading then return .1 end
   c=PlayerResource:GetSelectedHeroEntity(lab.owner);item=c:AddItemByName("item_ultimate_scepter");c:AddItemByName("item_aghanims_shard")
   phase="items";deadline=now+5
  elseif phase=="items"then
   if not A.scepter(c)or not A.shard(c)then assert(now<deadline,"custom ownership missing");return .1 end
   assert(not c:HasScepter(),"native Scepter leaked")
   assert(c:HasModifier("modifier_item_aghanims_shard")==not not B.hybrid_shards[c:GetUnitName()],"native Shard policy mismatch")
   local state=c:FindModifierByName("modifier_rift_aghanim_state")
   assert(state:GetModifierBonusStats_Strength()==10 and state:GetModifierHealthBonus()==175,"Scepter stats")
   if c:GetUnitName()=="npc_dota_hero_templar_assassin"then
    local a=c:FindAbilityByName("templar_assassin_trap_teleport")
    assert(not a or a:IsHidden()or not a:IsActivated(),"native Projection enabled")
   end
   for k,v in pairs(B.heroes[c:GetUnitName()][cases[i].path].scepter)do assert((P.get(c,k)or 0)>=v,"branch bonus missing "..k)end
   c:RemoveItem(item);c:AddItemByName("item_ultimate_scepter_2");phase="blessing";deadline=now+5
  elseif phase=="blessing"then
   if not c:HasModifier("modifier_rift_aghanim_blessing")then assert(now<deadline,"Blessing not consumed");return .1 end
   local state=c:FindModifierByName("modifier_rift_aghanim_state");state:OnIntervalThink()
   assert(A.scepter(c)and not c:HasScepter(),"Blessing ownership")
   assert(state:GetModifierBonusStats_Strength()==0 and state:GetModifierHealthBonus()==0,"Blessing leaked stats")
   print("[RIFT][AGHANIM] PASS "..cases[i].hero.." "..cases[i].path.." nativeScepter=false nativeShard="..tostring(c:HasModifier("modifier_item_aghanims_shard")).." blessing=true stats=0")
   phase="next"
  elseif phase=="ta_load"then
   assert(now<deadline,"TA timeout");if lab.loading then return .1 end
   c=PlayerResource:GetSelectedHeroEntity(lab.owner);local m=c:FindModifierByName("modifier_rift_ta_inner_peace")
   assert(m,"custom innate missing");assert(not c:HasModifier("modifier_templar_assassin_inner_peace"),"native innate still active")
   m:Reset();c:MoveToPosition(c:GetAbsOrigin()+Vector(450,0,0));phase="ta_move";deadline=now+1.2
  elseif phase=="ta_move"then
   if now<deadline then return .05 end
   local m=c:FindModifierByName("modifier_rift_ta_inner_peace");assert(m:GetStackCount()==100,"movement reset innate")
   print("[RIFT][AGHANIM] TA moving innate hp="..m:GetModifierConstantHealthRegen().." mana="..m:GetModifierConstantManaRegen())
   local enemy=CreateUnitByName("npc_dota_hero_axe",c:GetAbsOrigin()+Vector(800,0,0),true,nil,nil,c:GetTeamNumber()==2 and 3 or 2)
   ApplyDamage({victim=c,attacker=enemy,damage=50,damage_type=DAMAGE_TYPE_PURE})
   assert(m:GetStackCount()==0,"damage did not reset innate");UTIL_Remove(enemy)
   print("[RIFT][AGHANIM] TA positive damage resets stack=0; DONE");return nil
  end
  return .15
 end)
 if not ok then print("[RIFT][AGHANIM] ERROR case="..i.." "..tostring(result));return nil end
 return result
end,.1)
