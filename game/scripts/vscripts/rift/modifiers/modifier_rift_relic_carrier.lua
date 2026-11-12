-- Visible status of the Heart of the Rift carrier. Holds no state: the relic is
-- server event state (rift/core/relic_event), never an item. Removed on drop.
modifier_rift_relic_carrier = class({})

function modifier_rift_relic_carrier:IsHidden() return false end
function modifier_rift_relic_carrier:IsPurgable() return false end
function modifier_rift_relic_carrier:IsDebuff() return false end
function modifier_rift_relic_carrier:RemoveOnDeath() return true end
function modifier_rift_relic_carrier:GetTexture() return "item_aegis" end

function modifier_rift_relic_carrier:OnCreated(kv)
  self.slow = -(tonumber(kv and kv.slow) or 0)
  if IsServer() then
    local path = kv and kv.particle
    if path and path ~= "" then
      self.fx = ParticleManager:CreateParticle(path, PATTACH_OVERHEAD_FOLLOW, self:GetParent())
    end
  end
end

function modifier_rift_relic_carrier:OnDestroy()
  if IsServer() and self.fx then
    ParticleManager:DestroyParticle(self.fx, false)
    ParticleManager:ReleaseParticleIndex(self.fx)
    self.fx = nil
  end
end

function modifier_rift_relic_carrier:DeclareFunctions()
  return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_PROVIDES_FOW_POSITION }
end

function modifier_rift_relic_carrier:GetModifierMoveSpeedBonus_Percentage() return self.slow or 0 end
-- Shows the carrier's position to all through fog where supported; an explicit
-- periodic FOW viewer in relic_service is the reliable reveal.
function modifier_rift_relic_carrier:GetModifierProvidesFOWVision() return 1 end
