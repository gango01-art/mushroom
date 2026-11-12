-- PA magical dagger slow (values from the native Stifling Dagger).
modifier_rift_pa_dagger_slow = modifier_rift_pa_dagger_slow or ((type(class) == "function") and class({}) or {})
function modifier_rift_pa_dagger_slow:IsHidden() return false end
function modifier_rift_pa_dagger_slow:IsDebuff() return true end
function modifier_rift_pa_dagger_slow:IsPurgable() return true end
function modifier_rift_pa_dagger_slow:GetTexture() return "phantom_assassin_stifling_dagger" end
function modifier_rift_pa_dagger_slow:OnCreated(kv) self.slow = -(tonumber(kv and kv.slow) or 50) end
function modifier_rift_pa_dagger_slow:OnRefresh(kv) self:OnCreated(kv) end
function modifier_rift_pa_dagger_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_rift_pa_dagger_slow:GetModifierMoveSpeedBonus_Percentage() return self.slow end
