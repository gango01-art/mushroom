-- SF magical: short fear that is applied through debuff immunity (special rule of
-- this DUALITY direction). One per target per Requiem cast. VERIFY (OP-017): the
-- engine moves a unit with MODIFIER_STATE_FEARED; status resistance/dispel behaviour.
modifier_rift_sf_fear = modifier_rift_sf_fear or ((type(class) == "function") and class({}) or {})
function modifier_rift_sf_fear:IsHidden() return false end
function modifier_rift_sf_fear:IsDebuff() return true end
function modifier_rift_sf_fear:IsPurgable() return false end
function modifier_rift_sf_fear:GetTexture() return "nevermore_requiem" end
function modifier_rift_sf_fear:CheckState() return { [MODIFIER_STATE_FEARED] = true } end
