local B=require("rift.data.hero_balance").progression
modifier_rift_aghanim_state = modifier_rift_aghanim_state or ((type(class) == "function") and class({}) or {})
local M=modifier_rift_aghanim_state
function M:IsHidden()return true end
function M:IsPurgable()return false end
function M:RemoveOnDeath()return false end
function M:GetAttributes()return MODIFIER_ATTRIBUTE_PERMANENT end
function M:OnCreated()if IsServer()then self:OnIntervalThink();self:StartIntervalThink(.1)end end
function M:OnIntervalThink()
 local c=self:GetParent();local held=false
 if not c:IsIllusion()then
  for i=0,5 do local a=c:GetItemInSlot(i)
   if a and a:GetAbilityName()=="item_ultimate_scepter"then held=true end
  end
 end
 local shard=c:HasModifier("modifier_rift_aghanim_shard")
 local owned=held or c:HasModifier("modifier_rift_aghanim_blessing")
 local stack=(owned and 1 or 0)+(shard and 2 or 0)+(held and 4 or 0)
 if self:GetStackCount()~=stack then self:SetStackCount(stack);c:CalculateStatBonus(true)end
 -- Only these explicitly retained, shared Shards may activate stock C++ logic.
 -- Other heroes never receive native Scepter/Shard ownership.
 if shard and B.hybrid_shards[c:GetUnitName()]and not c:HasModifier("modifier_item_aghanims_shard")then
  require("rift.engine.mods").add(c,c,nil,"modifier_item_aghanims_shard",{})
 end
end
function M:Stats()return math.floor(self:GetStackCount()/4)%2==1 and B.agh_items or{}end
function M:DeclareFunctions()return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
 MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,MODIFIER_PROPERTY_HEALTH_BONUS,MODIFIER_PROPERTY_MANA_BONUS}end
function M:GetModifierBonusStats_Strength()return self:Stats().all_stats or 0 end
function M:GetModifierBonusStats_Agility()return self:Stats().all_stats or 0 end
function M:GetModifierBonusStats_Intellect()return self:Stats().all_stats or 0 end
function M:GetModifierHealthBonus()return self:Stats().health or 0 end
function M:GetModifierManaBonus()return self:Stats().mana or 0 end
