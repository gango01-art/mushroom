-- Explicit native item probe; never runs outside the single-player Tools lab.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local B=require("rift.data.solo_items")
local lab=gm.lab;lab:Clear();lab.free=false;assert(lab:Select("npc_dota_hero_axe","physical"))
local names={};for name in pairs(B.items)do names[#names+1]=name end;table.sort(names)
local index,phase,deadline,c,a,ally,enemy,base_stat,base_mr=0,"load",GameRules:GetGameTime()+40
local function log(s)print("[RIFT][SOLO_ITEMS] "..s)end
local function clean()
 c:Stop()
 for name in pairs(B.items)do local family=B.items[name].family;c:RemoveModifierByName("modifier_".."rift_item_"..family)end
 c:RemoveModifierByName("modifier_rift_item_recovery_lockout")
 for slot=0,16 do local it=c:GetItemInSlot(slot);if it then c:RemoveItem(it);UTIL_Remove(it)end end
end
GameRules:GetGameModeEntity():SetContextThink("rift_solo_items_probe",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime()
  if phase=="load"then
   assert(now<deadline,"precache timeout");if lab.loading then return .1 end
   c=PlayerResource:GetSelectedHeroEntity(lab.owner)
   ally=CreateUnitByName("npc_dota_hero_axe",c:GetAbsOrigin()+Vector(150,0,0),true,nil,nil,c:GetTeamNumber())
   enemy=CreateUnitByName("npc_dota_hero_axe",c:GetAbsOrigin()+Vector(200,0,0),true,nil,nil,c:GetTeamNumber()==2 and 3 or 2)
   for _,u in ipairs({ally,enemy})do u:SetIdleAcquire(false);u:Stop();u._rift_lab_target=true end
   phase="next"
  elseif phase=="next"then
   index=index+1;clean()
   if not names[index]then phase="recipe";index=1;return .3 end
   base_stat=c:GetStrength();base_mr=c:Script_GetMagicalArmorValue(nil)
   a=c:AddItemByName(names[index]);assert(a,"create "..names[index]);deadline=now+3;phase="passive"
  elseif phase=="passive"then
   local d=B.items[names[index]]
   assert(now<deadline,"passive timeout")
   if a:GetIntrinsicModifierName()~="modifier_rift_solo_item"then error("native implementation retained "..names[index])end
   local found=false;for _,m in ipairs(c:FindAllModifiersByName("modifier_rift_solo_item"))do if m:GetAbility()==a and m:GetStackCount()==1 then found=true end end
   if not found then return .1 end
   if d.stats.all_stats then assert(math.abs(c:GetStrength()-base_stat-d.stats.all_stats)<.01,"Crown stats")end
   assert(not ally:HasModifier("modifier_rift_solo_item"),"friendly passive leak")
   if d.active then
    -- Native upgrade families can share a cooldown (Drums/Bearing, for example).
    -- Each probe case is independent; do not carry the previous item's CD in.
    a:EndCooldown();c:GiveMana(10000);c:CastAbilityNoTarget(a,lab.owner);deadline=now+3;phase="active"
   else log("PASS "..names[index].." passive self-only");phase="next"end
  elseif phase=="active"then
   local d=B.items[names[index]];local x=d.active
   assert(now<deadline,"cast timeout "..names[index])
   local m=x.duration and c:FindModifierByName("modifier_".."rift_item_"..d.family)
   if x.duration and not m then return .1 end
   assert(not c:IsInvisible(),"item made hero invisible")
   assert(a:GetCooldownTimeRemaining()>0,"no actual item cooldown")
   if x.duration then assert(not ally:HasModifier("modifier_".."rift_item_"..d.family),"friendly active leak")end
   if names[index]=="item_glimmer_cape"then
    local mr=c:Script_GetMagicalArmorValue(nil);assert(mr>base_mr,"Glimmer MR did not increase");log("Glimmer STR bonus=10 activeMR="..mr)
   end
   if x.barrier then
    c:SetHealth(c:GetMaxHealth());local hp=c:GetHealth();local pool=m:GetStackCount()
    local wrong=x.damage_type=="magical"and DAMAGE_TYPE_PHYSICAL or DAMAGE_TYPE_MAGICAL
    ApplyDamage({victim=c,attacker=enemy,damage=100,damage_type=wrong})
    assert(m:GetStackCount()==pool,"wrong damage type consumed barrier")
    c:SetHealth(c:GetMaxHealth());hp=c:GetHealth()
    ApplyDamage({victim=c,attacker=enemy,damage=100,damage_type=x.damage_type=="magical"and DAMAGE_TYPE_MAGICAL or DAMAGE_TYPE_PHYSICAL})
    assert(math.abs(c:GetHealth()-hp)<.1,"barrier did not absorb")
    assert(m:GetStackCount()<pool,"barrier pool unchanged")
    log(names[index].." barrier="..pool.." -> "..m:GetStackCount())
   end
   if x.heal_lockout then assert(c:HasModifier("modifier_rift_item_recovery_lockout"),"heal lockout missing");assert(a:CastFilterResult()==UF_FAIL_CUSTOM,"heal lockout ignored")end
   log("PASS "..names[index].." cast self-only invisible=false cooldown="..a:GetCooldownTimeRemaining());phase="next"
  elseif phase=="recipe"then
   clean();local name=({"item_recipe_glimmer_cape","item_recipe_invis_sword"})[index]
   if not name then
    clean();UTIL_Remove(ally);UTIL_Remove(enemy);log("DONE 17/17 + 2 recipes");return nil
   end
   local r=B.recipes[name];for _,component in ipairs(r.components)do c:AddItemByName(component)end
   c:AddItemByName(name);deadline=now+3;phase="crafted"
  elseif phase=="crafted"then
   local name=({"item_recipe_glimmer_cape","item_recipe_invis_sword"})[index];local r=B.recipes[name]
   if not c:FindItemInInventory(r.result)then assert(now<deadline,"recipe failed "..name);return .1 end
   log("PASS craft "..r.result.." two Crowns");index=index+1;phase="recipe"
  end
  return .3
 end)
 if not ok then log("ERROR index="..index.." phase="..phase.." "..tostring(result));return nil end
 return result
end,.1)
