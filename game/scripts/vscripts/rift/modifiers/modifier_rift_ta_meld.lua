-- TA physical Meld state. Broken by moving or casting another ability; the attack
-- launched from Meld receives the bonus damage, then Meld ends (one attack only).
-- VERIFY (OP-013): bonus is included in the attack record launched while active.
local B = require("rift.data.hero_balance").ta.meld_physical

modifier_rift_ta_meld = modifier_rift_ta_meld or ((type(class) == "function") and class({}) or {})

function modifier_rift_ta_meld:IsHidden() return false end
function modifier_rift_ta_meld:IsPurgable() return false end
function modifier_rift_ta_meld:GetTexture() return "templar_assassin_meld" end

function modifier_rift_ta_meld:OnCreated()
  local a = self:GetAbility()
  self.bonus = B.bonus_damage[math.max(1, math.min(4, a and a:GetLevel() or 1))]
end

function modifier_rift_ta_meld:CheckState()
  return { [MODIFIER_STATE_INVISIBLE] = not self.striking }
end

function modifier_rift_ta_meld:DeclareFunctions()
  return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL, MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
           MODIFIER_EVENT_ON_UNIT_MOVED, MODIFIER_EVENT_ON_ABILITY_EXECUTED, MODIFIER_EVENT_ON_ATTACK }
end

function modifier_rift_ta_meld:GetModifierInvisibilityLevel() return 1 end
function modifier_rift_ta_meld:GetModifierPreAttack_BonusDamage() return self.bonus or 0 end

function modifier_rift_ta_meld:OnUnitMoved(p)
  if IsServer() and p.unit == self:GetParent() and not self.striking then self:Destroy() end
end

function modifier_rift_ta_meld:OnAbilityExecuted(p)
  if IsServer() and p.unit == self:GetParent() and p.ability ~= self:GetAbility() then self:Destroy() end
end

-- Attack launched (projectile created): bonus already applied to this record; end
-- Meld on the next frame so exactly one attack is empowered.
function modifier_rift_ta_meld:OnAttack(p)
  if not IsServer() or p.attacker ~= self:GetParent() or self.striking then return end
  self.striking = true
  local mod = self
  self:GetParent():SetContextThink("rift_meld_end", function()
    if mod and not mod:IsNull() then mod:Destroy() end
    return nil
  end, 0)
end
