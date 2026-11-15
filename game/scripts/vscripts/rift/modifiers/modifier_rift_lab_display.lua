-- Parked gallery actors are inspectable but never participate in combat.
modifier_rift_lab_display = modifier_rift_lab_display or ((type(class) == "function") and class({}) or {})
function modifier_rift_lab_display:IsHidden() return true end
function modifier_rift_lab_display:IsPurgable() return false end
function modifier_rift_lab_display:CheckState()
  return { [MODIFIER_STATE_ROOTED]=true, [MODIFIER_STATE_DISARMED]=true,
    [MODIFIER_STATE_SILENCED]=true, [MODIFIER_STATE_MUTED]=true,
    [MODIFIER_STATE_COMMAND_RESTRICTED]=true, [MODIFIER_STATE_INVULNERABLE]=true }
end
