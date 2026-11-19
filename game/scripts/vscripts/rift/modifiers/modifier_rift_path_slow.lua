modifier_rift_path_slow = modifier_rift_path_slow or ((type(class) == "function") and class({}) or {})
function modifier_rift_path_slow:IsHidden() return false end
function modifier_rift_path_slow:IsDebuff() return true end
function modifier_rift_path_slow:IsPurgable() return true end
function modifier_rift_path_slow:GetTexture()
  local a = self:GetAbility()
  return a and a:GetAbilityTextureName() or "crystal_maiden_crystal_nova"
end
function modifier_rift_path_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_rift_path_slow:GetModifierMoveSpeedBonus_Percentage()
  local a = self:GetAbility()
  local d = a and require("rift.data.expansion").abilities[a:GetAbilityName()]
  return -(d and d.slow or 0)
end
