modifier_rift_sleight = modifier_rift_sleight or ((type(class) == "function") and class({}) or {})
function modifier_rift_sleight:IsHidden() return true end
function modifier_rift_sleight:IsPurgable() return false end
function modifier_rift_sleight:CheckState()
  return { [MODIFIER_STATE_INVULNERABLE]=true, [MODIFIER_STATE_NO_UNIT_COLLISION]=true,
    [MODIFIER_STATE_COMMAND_RESTRICTED]=true, [MODIFIER_STATE_UNTARGETABLE]=true }
end
