-- Pure effect math for upgrades. Engine handlers read these totals; UI text is
-- filled from the same values (numbers are never duplicated in UI strings).

local Effects = {}

-- Handlers implemented in the engine. Registry validation uses this set.
Effects.HANDLERS = {
  stat_bonus = true,
  -- ultimate direction handlers implemented in the engine (abilities/modifiers)
  ta_psionic_crystal = true,   -- TA physical (verified OP-013/015)
  ta_psi_waves = true,         -- TA magical (verified OP-015)
  pa_phantom_spirit = true,    -- PA physical (verified OP-020/024)
  pa_storm_daggers = true,     -- PA magical (verified OP-023; dagger damage OP-025)
  sf_red_spheres = true,       -- SF physical (code complete; Dota check OP-016)
  sf_raze_rings = true,        -- SF magical (code complete; Dota check OP-017)
  lc_spell_amp_duel = true,    -- LC magical (code complete; Dota check OP-028)
  lc_champion_duel = true,     -- LC physical (code complete; Dota check OP-027)
  -- direction upgrades read by the abilities through Effects.bonus_total (OP-026)
  pa_spirit_cooldown = true,
  pa_chain_damage = true,
  pa_chain_chance = true,
  ta_crystal_cooldown = true,
  ta_wave_damage = true,
  ta_wave_length = true,
  lc_duel_cooldown = true,
  lc_champion_health = true,
  lc_statue_arrow = true,
  sf_sphere_damage = true,
  sf_requiem_cooldown = true,
  sf_ring_damage = true,
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

-- Sum of one value key over all implemented upgrades of a build (ability bonuses such as
-- "chain_damage_bonus"). Abilities read these instead of holding their own copies.
function Effects.bonus_total(registry, build, key)
  local total = 0
  for id, rank in pairs(build or {}) do
    local u = registry:get(id)
    if u and u.status == "implemented" and rank > 0 then
      total = total + (Effects.values_at(u, rank)[key] or 0)
    end
  end
  return total
end

return Effects
