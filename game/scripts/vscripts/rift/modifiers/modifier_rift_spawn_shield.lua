-- Respawn protection: blocks incoming damage for a short time. Removed by the
-- hero's own first attack or ability cast. Movement and passive regen keep it.
modifier_rift_spawn_shield = class({})

function modifier_rift_spawn_shield:IsHidden() return false end
function modifier_rift_spawn_shield:IsPurgable() return false end
function modifier_rift_spawn_shield:IsDebuff() return false end
function modifier_rift_spawn_shield:GetTexture() return "omniknight_guardian_angel" end

function modifier_rift_spawn_shield:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_EVENT_ON_ABILITY_EXECUTED,
  }
end

function modifier_rift_spawn_shield:GetModifierIncomingDamage_Percentage()
  return -100
end

function modifier_rift_spawn_shield:OnAttack(params)
  if IsServer() and params.attacker == self:GetParent() then self:Destroy() end
end

function modifier_rift_spawn_shield:OnAbilityExecuted(params)
  if IsServer() and params.unit == self:GetParent() then self:Destroy() end
end
