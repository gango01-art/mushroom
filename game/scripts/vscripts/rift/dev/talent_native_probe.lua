-- Run only after a full restart loading special_bonus_base talent definitions.
local gm=GameRules.RiftArena;local h=PlayerResource:GetSelectedHeroEntity(0);local P=require("rift.engine.progression")
assert(gm.dev and PlayerResource:GetPlayerCount()==1)
while h:GetLevel()<25 do h:HeroLevelUp(false)end
if not P.definition(h)then
 local id
 for _,d in ipairs(require("rift.data.ultimate_directions"))do if d.hero_id==h:GetUnitName()and d.direction=="physical"then id=d.id;break end end
 assert(id);assert(gm.upgrades.offers:dev_set_direction(0,id));gm.upgrades:ProcessEvents()
end
local _,path=P.definition(h);h:SetAbilityPoints(8)
local chosen={[1]=true,[4]=true,[5]=true,[8]=true}
for i=1,8 do local a=assert(h:FindAbilityByName(P.name(h:GetUnitName(),path,i)))
 assert(a:IsAttributeBonus(),"not a native talent "..a:GetAbilityName())
 assert(a:GetMaxLevel()==1,"talent can rank up repeatedly")
 assert(a:GetLevel()==0,"fresh unlearned talents required")
end
for _,i in ipairs({1,4,5,8})do local a=h:FindAbilityByName(P.name(h:GetUnitName(),path,i));h:UpgradeAbility(a);assert(a:GetLevel()==1)end
for i=1,8 do local a=h:FindAbilityByName(P.name(h:GetUnitName(),path,i))
 print("[RIFT][TALENT_FIX] index="..i.." level="..a:GetLevel().." attribute="..tostring(a:IsAttributeBonus()).." max="..a:GetMaxLevel().." native_result="..a:CanAbilityBeUpgraded())
 assert(a:GetLevel()==(chosen[i]and 1 or 0))
 assert(not P.can_train(h,path,i),"opposite talent must be locked by Duelity's level policy")
end
h:SetAbilityPoints(0)
print("[RIFT][TALENT_FIX] native picks4/4; opposite-level policy passed; client highlight requires a HUD check")
