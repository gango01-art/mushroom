-- LC physical Duel: permanent attack damage earned by champions. Stack count holds the
-- earned damage x10 (fractions kept to 0.1, same value on server and client).
modifier_rift_lc_duel_damage = modifier_rift_lc_duel_damage or ((type(class) == "function") and class({}) or {})
function modifier_rift_lc_duel_damage:IsHidden() return false end
function modifier_rift_lc_duel_damage:IsPurgable() return false end
function modifier_rift_lc_duel_damage:RemoveOnDeath() return false end
function modifier_rift_lc_duel_damage:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_rift_lc_duel_damage:GetTexture() return "legion_commander_duel" end
function modifier_rift_lc_duel_damage:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE } end
function modifier_rift_lc_duel_damage:GetModifierPreAttack_BonusDamage() return self:GetStackCount() / 10 end
