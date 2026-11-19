modifier_rift_pa_dagger_attack = modifier_rift_pa_dagger_attack or ((type(class) == "function") and class({}) or {})
function modifier_rift_pa_dagger_attack:IsHidden() return true end
function modifier_rift_pa_dagger_attack:IsPurgable() return false end
function modifier_rift_pa_dagger_attack:DeclareFunctions()
  return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE_TARGET,MODIFIER_EVENT_ON_ATTACK_LANDED}
end
function modifier_rift_pa_dagger_attack:GetModifierPreAttack_BonusDamage_Target(ev)
  local s=require("rift.engine.pa_dagger_attack").current(self:GetParent())
  return s and ev.target==s.target and s.bonus or 0
end
function modifier_rift_pa_dagger_attack:OnAttackLanded(ev)
  if not IsServer() then return end
  local s=require("rift.engine.pa_dagger_attack").current(self:GetParent())
  if s and ev.attacker==s.caster and ev.target==s.target then s.landed=true end
end
