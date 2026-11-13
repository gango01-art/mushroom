local Exec = require("rift.core.heroes.pa_physical")
local Storm = require("rift.core.pa_storm_daggers")
local B = require("rift.data.hero_balance").pa

T.case("PA physical: crit percent comes from the native value, fallback by rank", function()
  T.eq(Exec.crit_percent(325, 1, B.execution_physical.crit_fallback), 325)
  T.eq(Exec.crit_percent(0, 2, B.execution_physical.crit_fallback), 325)
  T.eq(Exec.crit_percent(nil, 9, B.execution_physical.crit_fallback), 450)
  T.eq(Exec.crit_percent(550, 3, B.execution_physical.crit_fallback), 550, "facet/talent value is used as is")
end)

T.case("PA physical: one hit = attack damage x crit, never negative", function()
  T.eq(Exec.hit_damage(100, 200), 200)
  T.eq(Exec.hit_damage(120, 450), 540)
  T.eq(Exec.hit_damage(-5, 200), 0)
end)

T.case("PA physical: spirit hits only a living vulnerable target that did not block", function()
  T.ok(Exec.can_hit({ exists = true, alive = true }))
  T.eq(Exec.can_hit(nil), false)
  T.eq(Exec.can_hit({ exists = false }), false, "disjointed")
  T.eq(Exec.can_hit({ exists = true, alive = false }), false, "dead")
  T.eq(select(2, Exec.can_hit({ exists = true, alive = true, invulnerable = true })), "invulnerable")
  T.eq(select(2, Exec.can_hit({ exists = true, alive = true, absorbed = true })), "absorbed")
end)

T.case("PA magical: values by ultimate rank; owner values at rank 1", function()
  local v = Storm.values_at(B.storm_magical, 1)
  T.eq(v.chain_chance, 0.20); T.eq(v.chain_damage, 300); T.eq(v.cast_context_seconds, 3)
  T.eq(Storm.values_at(B.storm_magical, 3).chain_damage, 460)
  T.eq(Storm.values_at(B.storm_magical, 7).chain_damage, 460, "rank clamped")
  T.eq(B.storm_magical.extra_targets, 1)
end)

T.case("PA balance arrays have the right length", function()
  for _, a in ipairs({ B.execution_physical.cooldown, B.execution_physical.mana, B.execution_physical.crit_fallback,
    B.storm_magical.chain_chance, B.storm_magical.chain_damage }) do T.eq(#a, 3) end
  for _, a in ipairs({ B.storm_magical.dagger_range, B.storm_magical.dagger_base_damage,
    B.storm_magical.dagger_attack_factor, B.storm_magical.dagger_slow_duration }) do T.eq(#a, 4) end
end)

T.case("PA magical: dev force_proc makes every paired cast proc, single casts never", function()
  local s = Storm.new(7)
  s.force_proc = true
  local v = Storm.values_at(B.storm_magical, 1)
  local _, proc = s:begin_cast(1, 10, 11, v, 0)
  T.eq(proc, true)
  local _, single = s:begin_cast(1, 10, nil, v, 0)
  T.eq(single, false)
end)

T.case("PA upgrades: bonus_total sums a key over implemented upgrades only", function()
  local F = require("fixtures")
  local Registry = require("rift.core.upgrade_registry")
  local Effects = require("rift.core.upgrade_effects")
  local ups, dirs = F.data("shipped")
  local reg = Registry.new(ups, dirs, { handlers = Effects.HANDLERS })
  T.eq(#reg:validate(), 0, table.concat(reg:validate(), "; "))
  T.eq(Effects.bonus_total(reg, { pa_static_edge = 2 }, "chain_damage_bonus"), 120)
  T.eq(Effects.bonus_total(reg, { pa_spirit_haste = 1, pa_static_edge = 1 }, "spirit_cooldown_reduction"), 2)
  T.eq(Effects.bonus_total(reg, { pa_bloodletter = 2 }, "crit_chance_bonus"), 0, "planned upgrade gives nothing")
  T.eq(Effects.bonus_total(reg, {}, "chain_damage_bonus"), 0)
end)

T.case("PA magical: upgrade bonuses add to chain values, chance capped at 1", function()
  local v = Storm.values_at(B.storm_magical, 1, { chain_damage = 120, chain_chance = 0.05 })
  T.eq(v.chain_damage, 420); T.ok(math.abs(v.chain_chance - 0.25) < 1e-9)
  T.eq(Storm.values_at(B.storm_magical, 1, { chain_chance = 5 }).chain_chance, 1)
end)

T.case("direction upgrades of TA/LC/SF: valid data, right direction, bonuses sum", function()
  local F = require("fixtures")
  local Registry = require("rift.core.upgrade_registry")
  local Effects = require("rift.core.upgrade_effects")
  local ups, dirs = F.data("shipped")
  local reg = Registry.new(ups, dirs, { handlers = Effects.HANDLERS })
  T.eq(#reg:validate(), 0, table.concat(reg:validate(), "; "))
  local expect = {
    ta_crystal_tempo = { "physical", "crystal_cooldown_reduction", 2 }, ta_wave_power = { "magical", "wave_damage_bonus", 45 },
    ta_wave_reach = { "magical", "wave_length_bonus", 200 }, lc_duel_haste = { "physical", "duel_cooldown_reduction", 16 },
    lc_champion_vigor = { "physical", "champion_health_pct", 20 }, lc_statue_barbs = { "magical", "statue_arrow_bonus", 40 },
    sf_sphere_edge = { "physical", "sphere_damage_pct", 20 }, sf_requiem_tempo = { "physical", "requiem_cooldown_reduction", 12 },
    sf_ring_burn = { "magical", "ring_damage_bonus", 40 },
  }
  for id, e in pairs(expect) do
    local u = reg:get(id)
    T.ok(u, id); T.eq(u.required_direction, e[1], id); T.eq(u.status, "implemented", id)
    T.eq(Effects.bonus_total(reg, { [id] = u.max_rank }, e[2]), e[3], id)
  end
end)
