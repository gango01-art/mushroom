local B = require("rift.data.hero_balance")
local F = require("fixtures")

local function resolve(ref)
  local t = B
  for part in ref:gmatch("[^.]+") do t = t and t[part] end
  return t
end

T.case("every direction has a resolvable balance_ref", function()
  local _, dirs = F.data("shipped")
  local n = 0
  for _, d in ipairs(dirs) do
    if d.balance_ref then n = n + 1; T.ok(resolve(d.balance_ref), d.id .. " -> " .. d.balance_ref) end
  end
  T.eq(n, 8)
end)

T.case("rank-indexed arrays have the right length", function()
  local ult = { B.lc.duel_physical.per_second, B.lc.duel_physical.permanent_cap, B.lc.duel_physical.cooldown,
    B.lc.duel_magical.base_spell_amp, B.lc.duel_magical.cap_spell_amp, B.sf.requiem_physical.sphere_regen,
    B.sf.requiem_physical.raze_bonus_fraction, B.sf.requiem_magical.ring_damage, B.sf.requiem_magical.immune_fear,
    B.ta.crystal_physical.radius, B.ta.crystal_physical.cooldown, B.ta.trap_magical.damage }
  for _, a in ipairs(ult) do T.eq(#a, 3) end
  local abil = { B.lc.statue.arrow_damage, B.lc.statue.health, B.ta.meld_physical.bonus_damage,
    B.ta.waves_magical.q_cooldown, B.ta.waves_magical.w_dash, B.ta.waves_magical.e_base }
  for _, a in ipairs(abil) do T.eq(#a, 4) end
  T.eq(#B.sf.requiem_magical.ring_radius, 3); T.eq(#B.lc.statue.shot_times, 4)
end)

T.case("owner-required values unchanged", function()
  local d = B.lc.duel_physical
  T.eq(d.per_second[3], 1.4); T.eq(d.victory_multiplier, 1.5); T.eq(d.champion_death_penalty_fraction, 0.30)
  T.eq(B.sf.requiem_physical.sphere_damage_fraction, 0.60); T.eq(B.sf.requiem_physical.duration, 15)
  T.eq(B.ta.crystal_physical.durability, 3); T.eq(B.ta.waves_magical.q_base, 120)
  T.eq(B.lc.statue.cdr_per_hit, 2); T.eq(B.lc.statue.cooldown, 25); T.eq(B.lc.duel_magical.cap_spell_amp[3], 20)
end)
