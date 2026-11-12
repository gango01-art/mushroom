-- LC magical statue: stationary, cannot be ordered; its arrows are fired by engine/lc_magic.
modifier_rift_lc_statue = modifier_rift_lc_statue or ((type(class) == "function") and class({}) or {})
function modifier_rift_lc_statue:IsHidden() return false end
function modifier_rift_lc_statue:IsPurgable() return false end
function modifier_rift_lc_statue:GetTexture() return "legion_commander_moment_of_courage" end
function modifier_rift_lc_statue:CheckState()
  return { [MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_DISARMED] = true,
           [MODIFIER_STATE_COMMAND_RESTRICTED] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end
function modifier_rift_lc_statue:DeclareFunctions() return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION } end
function modifier_rift_lc_statue:GetOverrideAnimation() return ACT_DOTA_IDLE end
