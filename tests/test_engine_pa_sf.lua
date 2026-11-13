-- Smoke tests of PA and SF engine code on the fake Dota API (tests/engine_stub.lua).
local Stub = require("engine_stub")
local B = require("rift.data.hero_balance")

local function pa_setup()
  local S = Stub.install()
  local pa = S.hero("npc_dota_hero_phantom_assassin", 0, 2, Vector(0, 0, 0), { Damage = 100 })
  local a = S.hero("npc_dota_hero_axe", 1, 3, Vector(400, 0, 0), {})
  local b = S.hero("npc_dota_hero_axe", 2, 3, Vector(600, 0, 0), {})
  return S, pa, a, b
end

local function land(S, ability)
  local list = S.projectiles
  S.projectiles = {}
  for _, p in ipairs(list) do ability:OnProjectileHit_ExtraData(p.Target, nil, p.ExtraData) end
end

T.case("PA execution: one crit hit = attack x 200%, physical, credited to PA; no hit when dodged", function()
  local S, pa, a = pa_setup()
  S.created = {}
  local ult = S.lua_ability("pa_phantom_execution", pa, 1)
  ult.cursor = a
  ult:OnSpellStart()
  T.eq(#S.projectiles, 1); T.eq(#S.created, 1, "spirit visual unit")
  land(S, ult)
  T.eq(#S.damage, 1); T.eq(S.damage[1].damage, 200); T.eq(S.damage[1].attacker, pa)
  T.ok(S.created[1].removed, "spirit removed on hit")
  ult:OnSpellStart()
  local p = S.projectiles[1]
  ult:OnProjectileHit_ExtraData(nil, nil, p.ExtraData) -- disjointed
  T.eq(#S.damage, 1, "no damage when dodged"); T.ok(S.created[2].removed, "spirit removed on dodge")
  T.eq(ult:GetCooldown(0), 24); T.eq(ult:GetManaCost(2), 120)
end)

T.case("PA execution: spell block and rank 3 multiplier", function()
  local S, pa, a = pa_setup()
  local ult = S.lua_ability("pa_phantom_execution", pa, 3)
  ult.cursor = a
  a.linkens = true
  ult:OnSpellStart(); land(S, ult)
  T.eq(#S.damage, 0, "blocked")
  a.linkens = false
  ult:OnSpellStart(); land(S, ult)
  T.eq(S.damage[1].damage, 450)
end)

T.case("PA storm dagger: two daggers, dagger formula, chain 300 once per target when forced", function()
  local S, pa, a, b = pa_setup()
  S.lua_ability("pa_storm_charge", pa, 1)
  local q = S.lua_ability("pa_storm_dagger", pa, 2)
  local store = require("rift.engine.pa_storm").store()
  store.force_proc = true
  q.cursor = a
  q:OnSpellStart()
  T.eq(#S.projectiles, 2, "primary + one extra target")
  land(S, q)
  local phys, magic = 0, 0
  for _, d in ipairs(S.damage) do
    if d.damage == 300 then magic = magic + 1 else phys = phys + 1; T.eq(d.damage, 70 + 100 * 0.45) end
  end
  T.eq(phys, 2); T.eq(magic, 2, "chain damage once per target")
  T.ok(a:HasModifier("modifier_rift_pa_dagger_slow")); T.ok(b:HasModifier("modifier_rift_pa_dagger_slow"))
end)

T.case("PA storm dagger: one dagger dodged -> no chain; single target -> one dagger", function()
  local S, pa, a, b = pa_setup()
  S.lua_ability("pa_storm_charge", pa, 1)
  local q = S.lua_ability("pa_storm_dagger", pa, 1)
  require("rift.engine.pa_storm").store().force_proc = true
  q.cursor = a
  q:OnSpellStart()
  local ps = S.projectiles; S.projectiles = {}
  q:OnProjectileHit_ExtraData(ps[1].Target, nil, ps[1].ExtraData)
  q:OnProjectileHit_ExtraData(nil, nil, ps[2].ExtraData) -- second dagger disjointed
  T.eq(#S.damage, 1, "only the dagger that hit; no chain")
  b.pos = Vector(5000, 0, 0)
  q:OnSpellStart()
  T.eq(#S.projectiles, 1)
end)

local function sf_setup()
  local S = Stub.install()
  local sf = S.hero("npc_dota_hero_nevermore", 0, 2, Vector(0, 0, 0), { Damage = 200 })
  local foe = S.hero("npc_dota_hero_axe", 1, 3, Vector(300, 0, 0), {})
  return S, sf, foe
end

T.case("SF spheres: an attack spends one sphere; its landing adds 60% physical once", function()
  local S, sf, foe = sf_setup()
  local ult = S.ability(1)
  local m = S.lua_modifier("modifier_rift_sf_spheres", sf, ult)
  T.eq(m:GetStackCount(), 4)
  m:OnAttack({ attacker = sf, target = foe, record = 7 })
  T.eq(m:GetStackCount(), 3)
  m:OnAttackLanded({ attacker = sf, target = foe, record = 7 })
  m:OnAttackLanded({ attacker = sf, target = foe, record = 7 }) -- duplicate landing event
  T.eq(#S.damage, 1); T.eq(S.damage[1].damage, 120)
  m:OnAttack({ attacker = sf, target = foe, record = 8 })
  m:OnAttackRecordDestroy({ attacker = sf, record = 8 }) -- missed: sphere spent, no damage
  m:OnAttackLanded({ attacker = sf, target = foe, record = 8 })
  T.eq(#S.damage, 1); T.eq(m:GetStackCount(), 2)
end)

T.case("SF spheres: Shadowraze bonus once per cast and victim", function()
  local S, sf, foe = sf_setup()
  local m = S.lua_modifier("modifier_rift_sf_spheres", sf, S.ability(1))
  local raze = { IsNull = function() return false end, GetAbilityName = function() return "nevermore_shadowraze1" end }
  m:OnAbilityExecuted({ unit = sf, ability = raze })
  m:OnTakeDamage({ attacker = sf, unit = foe, inflictor = raze })
  m:OnTakeDamage({ attacker = sf, unit = foe, inflictor = raze })
  T.eq(#S.damage, 1); T.eq(S.damage[1].damage, 200 * B.sf.requiem_physical.raze_bonus_fraction[1])
  m:OnAbilityExecuted({ unit = sf, ability = raze })
  m:OnTakeDamage({ attacker = sf, unit = foe, inflictor = raze })
  T.eq(#S.damage, 2, "a new cast may add the bonus again")
end)

T.case("SF rings: manual Requiem -> three rings, each damages a victim once; immune gets fear only", function()
  local S, sf, foe = sf_setup()
  foe.pos = Vector(300, 0, 0) -- on the first ring (radius 300)
  local m = S.lua_modifier("modifier_rift_sf_rings", sf, nil)
  local req = { GetAbilityName = function() return "nevermore_requiem" end, GetLevel = function() return 1 end }
  m:OnAbilityFullyCast({ unit = sf, ability = req })
  for _ = 1, 30 do S.advance(0.1); m:OnIntervalThink() end
  T.eq(#S.damage, 1, "foe stands on ring 1 only"); T.eq(S.damage[1].damage, 70)
  T.eq(#m.sessions, 0, "session finished and dropped")
  foe.immune = true
  m:OnAbilityFullyCast({ unit = sf, ability = req })
  T.ok(foe:HasModifier("modifier_rift_sf_fear"), "fear through immunity at cast")
  for _ = 1, 30 do S.advance(0.1); m:OnIntervalThink() end
  T.eq(#S.damage, 1, "no ring damage to an immune target")
  sf.dead = true
  m:OnAbilityFullyCast({ unit = sf, ability = req })
  T.eq(#m.sessions, 0, "death release creates no rings")
end)
