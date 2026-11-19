-- Legacy Lua talents only, retained for older in-memory Tools sessions.
-- Current generated talents use native special_bonus_base: ability_lua is not
-- IsAttributeBonus() even with AbilityType=ATTRIBUTES and ignores native picks.
local P=require("rift.engine.progression")
local B=require("rift.data.hero_balance").progression
for hero,paths in pairs(B.heroes)do for path,d in pairs(paths)do for i=1,#d.talents do
 local name=P.name(hero,path,i)
 local A=_G[name]or((type(class)=="function")and class({})or{});_G[name]=A
 local chosen_path,index=path,i
 function A:GetHeroLevelRequiredToUpgrade()
  local c=self:GetCaster();local row=math.ceil(index/2)
  local other=c and c:FindAbilityByName(P.name(c:GetUnitName(),chosen_path,index%2==1 and index+1 or index-1))
  return other and other:GetLevel()>0 and B.opposite_levels[row] or B.levels[row]
 end
 function A:OnUpgrade()
  if not IsServer()or self:GetLevel()<1 then return end
  if self:GetLevel()>1 then
   local c=self:GetCaster();local excess=self:GetLevel()-1
   self:SetLevel(1);c:SetAbilityPoints(c:GetAbilityPoints()+excess);return
  end
  local c=self:GetCaster()
  local gm=GameRules.RiftArena
  -- ReplaceHeroWith can copy learned talents before the new hero's level/path
  -- are initialized. Never refund or unlearn during that native construction.
  if c._rift_progression_transfer or self._rift_upgrade_refund
   or (gm and gm.lab and gm.lab.loading)or not P.definition(c)then return end
  if not P.can_train(c,chosen_path,index)then
   self._rift_upgrade_refund=true
   self:SetLevel(0);c:SetAbilityPoints(c:GetAbilityPoints()+1)
   self._rift_upgrade_refund=nil
   print("[RIFT][TALENT] rejected locked choice "..self:GetAbilityName())
  end
 end
end end end
