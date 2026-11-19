local B=require("rift.data.hero_balance").passives
modifier_rift_sven_mystic = modifier_rift_sven_mystic or ((type(class) == "function") and class({}) or {})
function modifier_rift_sven_mystic:IsHidden() return true end
function modifier_rift_sven_mystic:IsPurgable() return false end
function modifier_rift_sven_mystic:DeclareFunctions()
  return {MODIFIER_PROPERTY_AOE_BONUS_CONSTANT_STACKING,MODIFIER_PROPERTY_STATUS_RESISTANCE_CASTER}
end
local function level(self)
  local a=self:GetAbility()
  return not self:GetParent():PassivesDisabled() and a and not a:IsNull() and a:GetLevel() or 0
end
function modifier_rift_sven_mystic:GetModifierAoEBonusConstantStacking()
  return B.sven_radius[level(self)] or 0
end
function modifier_rift_sven_mystic:GetModifierStatusResistanceCaster()
  return B.sven_debuff[level(self)] or 0
end
