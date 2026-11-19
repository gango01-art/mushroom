local M = {}
function M.reduce(ability, seconds)
  if not ability or ability:IsNull() or seconds <= 0 then return end
  local left = math.max(0, ability:GetCooldownTimeRemaining() - seconds)
  ability:EndCooldown()
  if left > 0 then ability:StartCooldown(left) end
end
return M
