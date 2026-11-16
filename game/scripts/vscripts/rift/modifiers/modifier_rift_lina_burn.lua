local B=require("rift.data.hero_balance").lina
modifier_rift_lina_burn = modifier_rift_lina_burn or ((type(class) == "function") and class({}) or {})
function modifier_rift_lina_burn:IsHidden() return true end
function modifier_rift_lina_burn:IsPurgable() return false end
function modifier_rift_lina_burn:RemoveOnDeath() return false end
function modifier_rift_lina_burn:DeclareFunctions()
 return {MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE}
end
local function applies(ev)
 return ev.ability and ev.ability:GetAbilityName()=="lina_slow_burn" and ev.ability_special_value=="burn_damage_pct"
end
function modifier_rift_lina_burn:GetModifierOverrideAbilitySpecial(ev) return applies(ev) and 1 or 0 end
function modifier_rift_lina_burn:GetModifierOverrideAbilitySpecialValue(ev) return applies(ev) and B.burn_pct or 0 end
