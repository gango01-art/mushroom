-- Pure effect math for upgrades. Engine handlers read these totals; UI text is
-- filled from the same values (numbers are never duplicated in UI strings).

local Effects = {}

-- Handlers implemented in the engine. Registry validation uses this set.
Effects.HANDLERS = {
  stat_bonus = true,
}

Effects.STAT_KEYS = { "attack_damage", "move_speed", "armor", "health", "mana", "attack_speed",
                      "spell_amp", "health_regen", "status_resistance" }

-- values of an upgrade at a rank: { key = number }
function Effects.values_at(u, rank)
  local out = {}
  if not u or rank < 1 then return out end
  for k, list in pairs(u.values_by_rank or {}) do
    if type(list) == "table" then out[k] = list[math.min(rank, #list)] end
  end
  return out
end

-- Sum of stat_bonus values over a build { upgrade_id = rank }.
function Effects.stat_totals(registry, build)
  local totals = {}
  for _, k in ipairs(Effects.STAT_KEYS) do totals[k] = 0 end
  for id, rank in pairs(build or {}) do
    local u = registry:get(id)
    if u and u.effect_handler == "stat_bonus" and rank > 0 then
      for k, v in pairs(Effects.values_at(u, rank)) do
        if totals[k] ~= nil then totals[k] = totals[k] + v end
      end
    end
  end
  return totals
end

return Effects
