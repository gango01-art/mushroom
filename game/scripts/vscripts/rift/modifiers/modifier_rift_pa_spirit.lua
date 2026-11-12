-- Visual-only flying spirit of PA physical ultimate (Grimstroke Phantom's Embrace model).
-- Not a game object: cannot be hit, selected, ordered or blocked.
modifier_rift_pa_spirit = modifier_rift_pa_spirit or ((type(class) == "function") and class({}) or {})
function modifier_rift_pa_spirit:IsHidden() return true end
function modifier_rift_pa_spirit:IsPurgable() return false end
function modifier_rift_pa_spirit:CheckState()
  return { [MODIFIER_STATE_INVULNERABLE] = true, [MODIFIER_STATE_NO_HEALTH_BAR] = true,
           [MODIFIER_STATE_UNSELECTABLE] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
           [MODIFIER_STATE_NOT_ON_MINIMAP] = true, [MODIFIER_STATE_FLYING] = true,
           [MODIFIER_STATE_DISARMED] = true, [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
           [MODIFIER_STATE_ATTACK_IMMUNE] = true, [MODIFIER_STATE_MAGIC_IMMUNE] = true }
end
function modifier_rift_pa_spirit:DeclareFunctions() return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION } end
function modifier_rift_pa_spirit:GetOverrideAnimation() return ACT_DOTA_RUN end
