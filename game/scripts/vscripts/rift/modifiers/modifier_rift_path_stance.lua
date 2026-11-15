modifier_rift_path_stance = modifier_rift_path_stance or ((type(class) == "function") and class({}) or {})
function modifier_rift_path_stance:IsHidden() return false end
function modifier_rift_path_stance:IsPurgable() return true end
function modifier_rift_path_stance:GetTexture()
  local a = self:GetAbility()
  return a and a:GetAbilityTextureName() or "sven_gods_strength"
end
function modifier_rift_path_stance:OnCreated()
  if IsServer() then
    self.stats = require("rift.engine.path_combat").snapshot(self:GetParent())
    self.rank=self:GetAbility():GetLevel();self.hits = 0
  end
end
function modifier_rift_path_stance:OnRefresh() self:OnCreated(); if IsServer() then self:SetStackCount(0) end end
function modifier_rift_path_stance:DeclareFunctions()
  return { MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_PROPERTY_ATTACK_RANGE_BONUS }
end
function modifier_rift_path_stance:GetModifierAttackRangeBonus()
  local a = self:GetAbility()
  local d = a and require("rift.data.expansion").abilities[a:GetAbilityName()]
  return d and d.attack_range or 0
end
function modifier_rift_path_stance:OnAttackLanded(ev)
  if IsServer() then require("rift.engine.path_combat").stance_attack(self, ev) end
end
