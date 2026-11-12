-- Momentary caster modifier for the PA magical dagger hit: the attack deals
-- base damage + a reduced share of attack damage (native Stifling Dagger rules).
modifier_rift_pa_dagger_attack = modifier_rift_pa_dagger_attack or ((type(class) == "function") and class({}) or {})
function modifier_rift_pa_dagger_attack:IsHidden() return true end
function modifier_rift_pa_dagger_attack:IsPurgable() return false end
function modifier_rift_pa_dagger_attack:OnCreated(kv)
  self.base = tonumber(kv and kv.base) or 0
  self.factor = tonumber(kv and kv.factor) or 0
end
function modifier_rift_pa_dagger_attack:DeclareFunctions()
  return { MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end
function modifier_rift_pa_dagger_attack:GetModifierDamageOutgoing_Percentage() return self.factor or 0 end
function modifier_rift_pa_dagger_attack:GetModifierPreAttack_BonusDamage() return self.base or 0 end
