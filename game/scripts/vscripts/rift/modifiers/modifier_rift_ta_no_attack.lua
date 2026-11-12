-- TA magical: no normal attacks at all (attack capability removed, not 0 attack
-- speed): user attack orders, auto-acquire and forced attacks cannot attack.
-- Movement, spells and item actives stay available.
modifier_rift_ta_no_attack = modifier_rift_ta_no_attack or ((type(class) == "function") and class({}) or {})
function modifier_rift_ta_no_attack:IsHidden() return true end
function modifier_rift_ta_no_attack:IsPurgable() return false end
function modifier_rift_ta_no_attack:RemoveOnDeath() return false end
function modifier_rift_ta_no_attack:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_rift_ta_no_attack:OnCreated()
  if not IsServer() then return end
  local p = self:GetParent()
  self.prev = p:GetAttackCapability()
  p:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
end
function modifier_rift_ta_no_attack:OnDestroy()
  if IsServer() and self.prev then self:GetParent():SetAttackCapability(self.prev) end
end
