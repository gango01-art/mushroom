local B=require("rift.core.config").sanctuary
modifier_rift_sanctuary = modifier_rift_sanctuary or ((type(class) == "function") and class({}) or {})
local M=modifier_rift_sanctuary
function M:IsPurgable()return false end
function M:GetTexture()return "rune_regen"end
function M:OnCreated()
 if IsServer()then self:OnIntervalThink();self:StartIntervalThink(B.purge_interval)end
end
function M:OnIntervalThink()self:GetParent():Purge(false,true,false,true,true)end
function M:CheckState()return {[MODIFIER_STATE_INVULNERABLE]=true,[MODIFIER_STATE_DISARMED]=true,[MODIFIER_STATE_SILENCED]=true}end
function M:DeclareFunctions()return {MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,MODIFIER_PROPERTY_MANA_REGEN_CONSTANT}end
function M:GetModifierConstantHealthRegen()return self:GetParent():GetMaxHealth()*B.hp_regen_pct/100 end
function M:GetModifierConstantManaRegen()return self:GetParent():GetMaxMana()*B.mana_regen_pct/100 end
