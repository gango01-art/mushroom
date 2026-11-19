-- Scripted areas use the same policy for preview and collision. Native skills
-- retain Valve's item handling. No range, damage, tick or target-count scaling.
local B = require("rift.data.hero_balance")
local M = {}
function M.item_bonus(caster)
  -- GetItemInSlot is server-only in this client build. The hidden modifier
  -- replicates the inventory total for client-side radius previews.
  if not caster.GetItemInSlot then
    return caster:GetModifierStackCount("modifier_rift_area_items",caster)
  end
  local bonus, seen = 0, {}
  for slot = 0, 5 do
    local item = caster:GetItemInSlot(slot)
    if item and not item:IsNull() then
      local n = item:GetAbilityName()
      if (n == "item_shivas_guard" or n == "item_gungir") and not seen[n] then
        seen[n] = true
        bonus = bonus + math.max(0, item:GetSpecialValueFor("bonus_aoe"))
      end
    end
  end
  return bonus
end
function M.radius(caster, base)
  if not caster or caster:IsNull() or base <= 0 then return base end
  local bonus=M.item_bonus(caster)
  local passive = caster:FindAbilityByName("rift_sven_mystic_cleave")
  local own = passive and passive:GetLevel() > 0 and not caster:PassivesDisabled()
    and B.passives.sven_radius[passive:GetLevel()] or 0
  return base + own + math.min(base * B.area.max_fraction, bonus * B.area.item_efficiency)
end
return M
