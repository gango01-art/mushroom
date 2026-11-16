local B = require("rift.data.hero_balance")
local CD = require("rift.engine.cooldown")
modifier_rift_attack_cooldowns = modifier_rift_attack_cooldowns or ((type(class) == "function") and class({}) or {})
function modifier_rift_attack_cooldowns:IsHidden() return true end
function modifier_rift_attack_cooldowns:IsPurgable() return false end
function modifier_rift_attack_cooldowns:DeclareFunctions()
  return { MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end
function modifier_rift_attack_cooldowns:OnAttackLanded(ev)
  if not IsServer() then return end
  local p,a=self:GetParent(),self:GetAbility()
  if not a or a:IsNull() or a:GetAbilityName()~="rift_juggernaut_physical" or ev.attacker~=p
    or p:IsIllusion() or not ev.target or ev.target:IsNull() or ev.target:GetTeamNumber()==p:GetTeamNumber()
    or ev.target:IsBuilding() or ev.target:IsOther() then return end
  CD.reduce(a,require("rift.data.expansion").abilities.rift_juggernaut_physical.hit_cdr[a:GetLevel()])
end
function modifier_rift_attack_cooldowns:OnAbilityFullyCast(ev)
  if not IsServer() then return end
  local a=self:GetAbility()
  if a and not a:IsNull() and a:GetAbilityName()=="pa_phantom_execution" and ev.unit==self:GetParent()
    and ev.ability and ev.ability:GetAbilityName()=="phantom_assassin_stifling_dagger" then
    CD.reduce(a,B.passives.pa_dagger_cdr[a:GetLevel()])
  end
end
