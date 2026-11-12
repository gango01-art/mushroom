-- TA magical Q defence: N instances, each blocks up to shield_per_instance of one
-- incoming damage instance, then is consumed. Offensive bonus does not exist.
local B = require("rift.data.hero_balance").ta.refraction_magical
modifier_rift_ta_refraction = modifier_rift_ta_refraction or ((type(class) == "function") and class({}) or {})
function modifier_rift_ta_refraction:IsHidden() return false end
function modifier_rift_ta_refraction:IsPurgable() return false end
function modifier_rift_ta_refraction:GetTexture() return "templar_assassin_refraction" end
function modifier_rift_ta_refraction:OnCreated()
  if not IsServer() then return end
  local a = self:GetAbility()
  self:SetStackCount(B.instances[math.max(1, math.min(4, a and a:GetLevel() or 1))])
end
function modifier_rift_ta_refraction:OnRefresh() self:OnCreated() end
function modifier_rift_ta_refraction:DeclareFunctions() return { MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK } end
function modifier_rift_ta_refraction:GetModifierTotal_ConstantBlock(kv)
  if not IsServer() or not kv or (kv.damage or 0) <= 0 then return 0 end
  local block = math.min(kv.damage, B.shield_per_instance)
  local n = self:GetStackCount() - 1
  if n <= 0 then self:Destroy() else self:SetStackCount(n) end
  return block
end
