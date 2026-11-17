local gm=GameRules.RiftArena;assert(gm.dev and PlayerResource:GetPlayerCount()==1)
local h=PlayerResource:GetSelectedHeroEntity(0);local P=require("rift.engine.progression");local _,path=P.definition(h)
assert(path,"choose a path first")
for i=1,8 do local a=h:FindAbilityByName(P.name(h:GetUnitName(),path,i))
 print("[RIFT][TALENT_NATIVE] index="..i.." level="..a:GetLevel().." type="..a:GetAbilityType().." attribute="..tostring(a:IsAttributeBonus()).." required="..a:GetHeroLevelRequiredToUpgrade().." native_can_upgrade="..tostring(a:CanAbilityBeUpgraded()).." policy="..tostring(P.can_train(h,path,i)))
end
