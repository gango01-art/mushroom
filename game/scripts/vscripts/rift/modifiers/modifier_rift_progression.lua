local P=require("rift.engine.progression")
modifier_rift_progression = modifier_rift_progression or ((type(class) == "function") and class({}) or {})
function modifier_rift_progression:IsHidden()return true end
function modifier_rift_progression:IsPurgable()return false end
function modifier_rift_progression:RemoveOnDeath()return false end
function modifier_rift_progression:GetAttributes()return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_rift_progression:OnCreated()
 if IsServer()then self:StartIntervalThink(.25)end
end
function modifier_rift_progression:OnIntervalThink()
 local t=P.totals(self:GetParent());local parts={}
 for _,k in ipairs({"attack_damage","health","attack_speed","move_speed","spell_amp","mana_regen","cast_range"})do parts[#parts+1]=t[k]or 0 end
 local stamp=table.concat(parts,":")
 if self.stamp~=stamp then self.stamp=stamp;self:GetParent():CalculateStatBonus(true)end
end
function modifier_rift_progression:DeclareFunctions()
 return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,MODIFIER_PROPERTY_HEALTH_BONUS,
 MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
 MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
 MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
 MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE}
end
function modifier_rift_progression:GetModifierPreAttack_BonusDamage()return P.get(self:GetParent(),"attack_damage")end
function modifier_rift_progression:GetModifierHealthBonus()return P.get(self:GetParent(),"health")end
function modifier_rift_progression:GetModifierAttackSpeedBonus_Constant()return P.get(self:GetParent(),"attack_speed")end
function modifier_rift_progression:GetModifierMoveSpeedBonus_Constant()return P.get(self:GetParent(),"move_speed")end
function modifier_rift_progression:GetModifierSpellAmplify_Percentage()return P.get(self:GetParent(),"spell_amp")end
function modifier_rift_progression:GetModifierConstantManaRegen()return P.get(self:GetParent(),"mana_regen")end
function modifier_rift_progression:GetModifierCastRangeBonusStacking()return P.get(self:GetParent(),"cast_range")end
-- Magical SF keeps the native Requiem implementation, so its cooldown uses the
-- native special override. Custom ultimates call the same policy directly.
function modifier_rift_progression:GetModifierOverrideAbilitySpecial(p)
 if p and p.ability and p.ability:GetAbilityName()=="nevermore_requiem"
 and p.ability_special_value=="AbilityCooldown"and P.primary(self:GetParent(),p.ability)then return 1 end
 return 0
end
function modifier_rift_progression:GetModifierOverrideAbilitySpecialValue(p)
 local base=p.ability:GetLevelSpecialValueNoOverride(p.ability_special_value,p.ability_special_level)
 return P.cooldown(self:GetParent(),p.ability,base)
end
