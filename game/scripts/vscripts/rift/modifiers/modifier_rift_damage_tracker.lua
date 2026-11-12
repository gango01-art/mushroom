-- Hidden permanent modifier on every real hero. Reports post-mitigation damage
-- taken to the game mode for assist / environment-kill attribution.
modifier_rift_damage_tracker = class({})

function modifier_rift_damage_tracker:IsHidden() return true end
function modifier_rift_damage_tracker:IsPurgable() return false end
function modifier_rift_damage_tracker:RemoveOnDeath() return false end
function modifier_rift_damage_tracker:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_rift_damage_tracker:DeclareFunctions()
  return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_rift_damage_tracker:OnTakeDamage(params)
  if not IsServer() then return end
  if params.unit ~= self:GetParent() then return end
  local gm = GameRules.RiftArena
  if gm then gm:OnHeroDamaged(params.unit, params.attacker, params.damage) end
end
