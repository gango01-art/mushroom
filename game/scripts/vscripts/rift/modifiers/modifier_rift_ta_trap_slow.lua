-- TA magical R slow (trap_debuff_policy: only this slow; no silence/extra effects).
modifier_rift_ta_trap_slow = modifier_rift_ta_trap_slow or ((type(class) == "function") and class({}) or {})
function modifier_rift_ta_trap_slow:IsHidden() return false end
function modifier_rift_ta_trap_slow:IsDebuff() return true end
function modifier_rift_ta_trap_slow:IsPurgable() return true end
function modifier_rift_ta_trap_slow:GetTexture() return "templar_assassin_psionic_trap" end
function modifier_rift_ta_trap_slow:OnCreated(kv) self.slow = -(tonumber(kv and kv.slow) or 30) end
function modifier_rift_ta_trap_slow:OnRefresh(kv) self:OnCreated(kv) end
function modifier_rift_ta_trap_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_rift_ta_trap_slow:GetModifierMoveSpeedBonus_Percentage() return self.slow end
