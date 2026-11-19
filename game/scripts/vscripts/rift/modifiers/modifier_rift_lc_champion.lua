-- LC physical Duel champion: reports its landed hits on the duel target and its killer
-- to the session; 90% attack rate is already in the snapshotted base attack time.
modifier_rift_lc_champion = modifier_rift_lc_champion or ((type(class) == "function") and class({}) or {})
function modifier_rift_lc_champion:IsHidden() return false end
function modifier_rift_lc_champion:IsPurgable() return false end
function modifier_rift_lc_champion:GetTexture() return "legion_commander_duel" end
function modifier_rift_lc_champion:OnCreated(kv)
  self.evasion=tonumber(kv.evasion) or 0;self.resistance=tonumber(kv.status_resistance) or 0
  if IsServer() then self.magic_resistance=tonumber(kv.magic_resistance);self:StartIntervalThink(.1) end
end
function modifier_rift_lc_champion:OnIntervalThink()
  if not self.magic_resistance then return end
  local p=self:GetParent()
  local current=p:Script_GetMagicalArmorValue(nil)
  if current>=1 or math.abs(current-self.magic_resistance)<.0001 then return end
  -- Avoid counting nearby item auras twice after copying the owner's total MR.
  local base=p:GetBaseMagicalResistanceValue()/100
  local adjusted=1-(1-self.magic_resistance)*(1-base)/(1-current)
  p:SetBaseMagicalResistanceValue(math.max(-100,math.min(99.9,adjusted*100)))
end
function modifier_rift_lc_champion:GetModifierEvasion_Constant() return self.evasion end
function modifier_rift_lc_champion:GetModifierStatusResistanceStacking() return self.resistance end
function modifier_rift_lc_champion:DeclareFunctions()
  return { MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_EVENT_ON_DEATH,MODIFIER_PROPERTY_EVASION_CONSTANT,MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING }
end
local function session(self)
  return require("rift.engine.lc_duel_session").by_champion(self:GetParent())
end
function modifier_rift_lc_champion:OnAttackLanded(params)
  if not IsServer() or params.attacker ~= self:GetParent() then return end
  local s = session(self)
  if s and params.target == s.target then s.duel:record_champion_hit(GameRules:GetGameTime(), params.damage or 0) end
end
function modifier_rift_lc_champion:OnDeath(params)
  if not IsServer() or params.unit ~= self:GetParent() then return end
  local s = session(self)
  if s then s.champion_killer = params.attacker end
end
