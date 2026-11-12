-- Hidden permanent modifier holding the hero's summed stat_bonus upgrades.
-- Server computes totals from the authoritative build and transmits them to
-- clients (custom transmitter data) so client-side stat display matches.
-- Use the engine `class` helper when present, a plain table otherwise (a load-time
-- error here makes the engine report "unknown modifier type").
modifier_rift_upgrade_stats = modifier_rift_upgrade_stats or ((type(class) == "function") and class({}) or {})

local KEYS = { "attack_damage", "move_speed", "armor", "health", "mana", "attack_speed",
               "spell_amp", "health_regen", "status_resistance" }

function modifier_rift_upgrade_stats:IsHidden() return true end
function modifier_rift_upgrade_stats:IsPurgable() return false end
function modifier_rift_upgrade_stats:RemoveOnDeath() return false end
function modifier_rift_upgrade_stats:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_rift_upgrade_stats:OnCreated()
  self.v = {}
  for _, k in ipairs(KEYS) do self.v[k] = 0 end
  if IsServer() then
    self:SetHasCustomTransmitterData(true)
    self:Pull()
  end
end

function modifier_rift_upgrade_stats:OnRefresh()
  if IsServer() then self:Pull() end
end

-- Server: read totals from the game mode and push to clients.
function modifier_rift_upgrade_stats:Pull()
  local gm = GameRules.RiftArena
  local parent = self:GetParent()
  if not gm or not gm.upgrades then return end
  local totals = gm.upgrades:StatTotals(parent:GetPlayerOwnerID())
  for _, k in ipairs(KEYS) do self.v[k] = totals[k] or 0 end
  self:SendBuffRefreshToClients()
  if parent.CalculateStatBonus then parent:CalculateStatBonus(true) end
end

function modifier_rift_upgrade_stats:AddCustomTransmitterData()
  local t = {}
  for _, k in ipairs(KEYS) do t[k] = self.v[k] end
  return t
end

function modifier_rift_upgrade_stats:HandleCustomTransmitterData(data)
  self.v = self.v or {}
  for _, k in ipairs(KEYS) do self.v[k] = data[k] or 0 end
end

function modifier_rift_upgrade_stats:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
  }
end

function modifier_rift_upgrade_stats:GetModifierPreAttack_BonusDamage() return self.v.attack_damage end
function modifier_rift_upgrade_stats:GetModifierMoveSpeedBonus_Constant() return self.v.move_speed end
function modifier_rift_upgrade_stats:GetModifierPhysicalArmorBonus() return self.v.armor end
function modifier_rift_upgrade_stats:GetModifierHealthBonus() return self.v.health end
function modifier_rift_upgrade_stats:GetModifierManaBonus() return self.v.mana end
function modifier_rift_upgrade_stats:GetModifierAttackSpeedBonus_Constant() return self.v.attack_speed end
function modifier_rift_upgrade_stats:GetModifierSpellAmplify_Percentage() return self.v.spell_amp end
function modifier_rift_upgrade_stats:GetModifierConstantHealthRegen() return self.v.health_regen end
function modifier_rift_upgrade_stats:GetModifierStatusResistanceStacking() return self.v.status_resistance end
