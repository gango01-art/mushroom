-- DEV ONLY test dummy: cannot attack, cast, use passives or be ordered; stays where spawned.
modifier_rift_dummy = modifier_rift_dummy or ((type(class) == "function") and class({}) or {})

function modifier_rift_dummy:IsHidden() return false end
function modifier_rift_dummy:IsPurgable() return false end
function modifier_rift_dummy:RemoveOnDeath() return true end
function modifier_rift_dummy:GetTexture() return "item_ward_observer" end

function modifier_rift_dummy:CheckState()
  -- PASSIVES_DISABLED (Break): no Counter Helix / innate damage back to the tester (OP-013 report).
  return { [MODIFIER_STATE_DISARMED] = true, [MODIFIER_STATE_SILENCED] = true, [MODIFIER_STATE_MUTED] = true,
           [MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
           [MODIFIER_STATE_PASSIVES_DISABLED] = true }
end
