-- LC magical Duel: one spell amp modifier. Stack count = percent x10 (same on server and
-- client). The earned points live in engine/lc_magic, not here: Break only suspends the bonus.
modifier_rift_lc_spell_amp = modifier_rift_lc_spell_amp or ((type(class) == "function") and class({}) or {})
function modifier_rift_lc_spell_amp:IsHidden() return self:GetStackCount() == 0 end
function modifier_rift_lc_spell_amp:IsPurgable() return false end
function modifier_rift_lc_spell_amp:RemoveOnDeath() return false end
function modifier_rift_lc_spell_amp:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_rift_lc_spell_amp:GetTexture() return "legion_commander_duel" end
function modifier_rift_lc_spell_amp:OnCreated()
  if IsServer() then self:StartIntervalThink(0.25); self:OnIntervalThink() end
end
function modifier_rift_lc_spell_amp:OnIntervalThink()
  local amp = require("rift.engine.lc_magic").spell_amp(self:GetParent())
  local stacks = math.floor(amp * 10 + 1e-6)
  if self:GetStackCount() ~= stacks then self:SetStackCount(stacks) end
end
function modifier_rift_lc_spell_amp:DeclareFunctions() return { MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,MODIFIER_PROPERTY_TOOLTIP,MODIFIER_PROPERTY_TOOLTIP2 } end
function modifier_rift_lc_spell_amp:GetModifierSpellAmplify_Percentage() return self:GetStackCount() / 10 end
function modifier_rift_lc_spell_amp:OnTooltip() return self:GetStackCount()/10 end
function modifier_rift_lc_spell_amp:OnTooltip2()
 local a=self:GetParent():FindAbilityByName("lc_duel_magical")
 local base=a and require("rift.data.hero_balance").lc.duel_magical.base_spell_amp[a:GetLevel()] or 0
 return math.max(0,self:GetStackCount()/10-base)
end
