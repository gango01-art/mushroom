-- Pure rules for replacing an ability when a direction is applied.
-- Policy "keep_rank_keep_cooldown": the new ability gets the replaced one's level
-- (never more), and the remaining cooldown carries over (clamped to the new
-- ability's full cooldown). Never refunds points, never resets a used ability.

local Transfer = {}

-- from: { level, cooldown_remaining }, to: { max_level, full_cooldown_at(level) -> seconds }
function Transfer.plan(policy, from, to)
  assert(policy == "keep_rank_keep_cooldown", "unsupported transfer policy " .. tostring(policy))
  local level = math.max(0, math.min(from.level or 0, to.max_level or 0))
  local cd = math.max(0, from.cooldown_remaining or 0)
  if level > 0 and to.full_cooldown_at then
    local full = to.full_cooldown_at(level)
    if full and full >= 0 then cd = math.min(cd, full) end
  end
  if level == 0 then cd = 0 end -- unlearned stays unlearned; nothing to cool down
  return { level = level, cooldown = cd, refund_points = 0 }
end

return Transfer
