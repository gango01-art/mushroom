local B = require("rift.data.hero_balance")
local CD = require("rift.engine.cooldown")
modifier_rift_attack_cooldowns = modifier_rift_attack_cooldowns or ((type(class) == "function") and class({}) or {})
function modifier_rift_attack_cooldowns:IsHidden() return true end
function modifier_rift_attack_cooldowns:IsPurgable() return false end
function modifier_rift_attack_cooldowns:DeclareFunctions()
  return { MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
    MODIFIER_EVENT_ON_ATTACK_RECORD,MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY }
end
function modifier_rift_attack_cooldowns:OnAttackRecord(ev)
  if not IsServer() or ev.attacker~=self:GetParent() or not self:GetParent()._rift_sleight_attack then return end
  self.sleight_records=self.sleight_records or {};self.sleight_records[ev.record]=true
end
function modifier_rift_attack_cooldowns:OnAttackRecordDestroy(ev)
  if self.sleight_records then self.sleight_records[ev.record]=nil end
end
function modifier_rift_attack_cooldowns:OnAttackLanded(ev)
  if not IsServer() then return end
  local p,a=self:GetParent(),self:GetAbility()
  if not a or a:IsNull() or ev.attacker~=p
    or p:IsIllusion() or not ev.target or ev.target:IsNull() or ev.target:GetTeamNumber()==p:GetTeamNumber()
    or ev.target:IsBuilding() or ev.target:IsOther() then return end
  local name=a:GetAbilityName()
  if name=="rift_juggernaut_physical" then
    local d=require("rift.data.expansion").abilities.rift_juggernaut_physical
    local sleight=p._rift_sleight_attack or (self.sleight_records and self.sleight_records[ev.record])
    if sleight then CD.reduce(a,d.hit_cdr[a:GetLevel()])
    elseif not ev.no_attack_cooldown then CD.reduce(a,d.ordinary_hit_cdr) end
  elseif name=="pa_phantom_execution" and not ev.no_attack_cooldown then
    CD.reduce(a,B.passives.pa_attack_cdr)
  end
end
function modifier_rift_attack_cooldowns:OnAbilityFullyCast(ev)
  if not IsServer() then return end
  local a=self:GetAbility()
  if a and not a:IsNull() and a:GetAbilityName()=="pa_phantom_execution" and ev.unit==self:GetParent()
    and ev.ability and ev.ability:GetAbilityName()=="phantom_assassin_stifling_dagger" then
    CD.reduce(a,B.passives.pa_dagger_cdr[a:GetLevel()])
  end
end
