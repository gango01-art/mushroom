-- LC physical Duel: Legion Commander on the throne. Invulnerable, cannot move, attack,
-- cast or use items while her champion fights. Removed only by the session cleanup
-- (engine/lc_duel_session); the duration is a safety net against a lost session.
modifier_rift_lc_throne = modifier_rift_lc_throne or ((type(class) == "function") and class({}) or {})
function modifier_rift_lc_throne:IsHidden() return false end
function modifier_rift_lc_throne:IsPurgable() return false end
function modifier_rift_lc_throne:IsPurgeException() return false end
function modifier_rift_lc_throne:GetTexture() return "legion_commander_duel" end
function modifier_rift_lc_throne:CheckState()
  return { [MODIFIER_STATE_INVULNERABLE] = true, [MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_DISARMED] = true,
           [MODIFIER_STATE_SILENCED] = true, [MODIFIER_STATE_MUTED] = true,
           [MODIFIER_STATE_COMMAND_RESTRICTED] = true }
end
