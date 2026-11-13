-- Smoke tests of the LC engine modules on the fake Dota API (tests/engine_stub.lua).
local Stub = require("engine_stub")
local B = require("rift.data.hero_balance").lc

local function near(a, b, msg) T.ok(math.abs(a - b) < 1e-6, (msg or "near") .. ": " .. tostring(a) .. " vs " .. tostring(b)) end

local function duel_setup()
  local S = Stub.install()
  local Session = require("rift.engine.lc_duel_session")
  Session.owners, Session.sessions = {}, {}
  local lc = S.hero("npc_dota_hero_legion_commander", 0, 2, Vector(0, 0, 0),
    { Damage = 100, Armor = 5, MaxHealth = 2000, Health = 1000, APS = 1.0, IdealSpeed = 330 })
  local foe = S.hero("npc_dota_hero_axe", 1, 3, Vector(300, 0, 0), { MaxHealth = 1500 })
  return S, Session, lc, foe
end

T.case("LC duel: snapshot, throne, 10 payouts with hits, timeout cleanup", function()
  local S, Session, lc, foe = duel_setup()
  T.ok(Session.start(lc, S.ability(1), foe, 1))
  local champ = S.created[1]
  T.eq(champ.props.BaseDamageMin, 100); T.eq(champ.props.PhysicalArmorBaseValue, 5)
  T.eq(champ.props.MaxHealth, 2000); T.eq(champ.props.Health, 1000, "same HP percent")
  near(champ.props.BaseAttackTime, 1 / 0.9, "90% attacks per second")
  T.ok(lc:HasModifier("modifier_rift_lc_throne")); T.ok(lc:IsInvulnerable())
  local s = Session.sessions[0]
  for _ = 1, 110 do
    if not s.done then s.duel:record_champion_hit(S.now, 50) end
    S.advance(0.1)
  end
  T.ok(s.done); T.eq(s.duel.reason, "timeout")
  T.ok(champ.removed, "champion removed, not killed")
  T.ok(not lc:HasModifier("modifier_rift_lc_throne"), "throne removed")
  near(Session.owner_state(0).earned, 8.0)
  T.eq(lc:FindModifierByName("modifier_rift_lc_duel_damage"):GetStackCount(), 80)
  T.eq(#S.damage, 0, "no penalty on timeout")
  T.eq(Session.sessions[0], nil)
  T.eq(champ.attack_target, foe, "champion ordered onto the duel target only")
end)

T.case("LC duel: champion death -> 30% max HP pure damage credited to the killer, stun, one cleanup", function()
  local S, Session, lc, foe = duel_setup()
  Session.start(lc, S.ability(1), foe, 1)
  local s = Session.sessions[0]
  S.advance(1.0)
  s.champion_killer = foe
  S.created[1].dead = true
  S.advance(0.2)
  T.ok(s.done); T.eq(s.duel.reason, "champion_death")
  T.eq(#S.damage, 1); T.eq(S.damage[1].damage, 600); T.eq(S.damage[1].attacker, foe); T.eq(S.damage[1].victim, lc)
  T.ok(lc:HasModifier("modifier_stunned")); T.eq(lc.mods.modifier_stunned.kv.duration, 1.0)
  T.ok(not lc:HasModifier("modifier_rift_lc_throne"))
  Session.finish(s, nil)
  T.eq(#S.damage, 1, "second finish does nothing")
end)

T.case("LC duel: leash break and second cast while one is live", function()
  local S, Session, lc, foe = duel_setup()
  Session.start(lc, S.ability(1), foe, 1)
  T.eq(Session.start(lc, S.ability(1), foe, 1), false, "one session per owner")
  local s = Session.sessions[0]
  foe.pos = Vector(2000, 0, 0)
  S.advance(1.5)
  T.ok(s.done); T.eq(s.duel.reason, "leash_break"); T.eq(#S.damage, 0)
end)

T.case("LC duel: victory tops the reward up to 12 at rank 1", function()
  local S, Session, lc, foe = duel_setup()
  Session.start(lc, S.ability(1), foe, 1)
  local s = Session.sessions[0]
  s.duel:record_champion_hit(S.now, 400) -- >= 20% of 1500
  S.advance(0.5)
  foe.dead = true
  S.advance(0.2)
  T.eq(s.duel.reason, "victory"); near(Session.owner_state(0).earned, 12)
end)

T.case("LC statue: four shots on schedule, arrow damage, cooldown cut 25 -> 17, replace old statue", function()
  local S = Stub.install()
  local Magic = require("rift.engine.lc_magic")
  Magic.owners, Magic.statues, Magic.by_id = {}, {}, {}
  local lc = S.hero("npc_dota_hero_legion_commander", 0, 2, Vector(0, 0, 0), {})
  local foe = S.hero("npc_dota_hero_axe", 1, 3, Vector(400, 0, 0), {})
  local ability = S.ability(2)
  ability:StartCooldown(B.statue.cooldown)
  T.ok(Magic.summon(lc, ability, Vector(100, 0, 0), 2))
  local statue = S.created[1]
  T.eq(statue.props.MaxHealth, 550); T.eq(statue.props.BaseMagicalResistanceValue, 25)
  S.advance(10.5)
  T.eq(#S.projectiles, 4, "four arrows")
  T.ok(statue.removed, "expired statue removed")
  for _, p in ipairs(S.projectiles) do Magic.on_arrow_hit(ability, p.Target, p.ExtraData) end
  Magic.on_arrow_hit(ability, foe, S.projectiles[1].ExtraData) -- duplicate event
  T.eq(#S.damage, 5); T.eq(S.damage[1].damage, 90); T.eq(S.damage[1].attacker, lc)
  near(ability:GetCooldownTimeRemaining(), 25 - 10.5 - 8, "cooldown reduced by 8 in total")
  Magic.summon(lc, ability, Vector(0, 0, 0), 2)
  Magic.summon(lc, ability, Vector(50, 0, 0), 2)
  T.ok(S.created[2].removed, "old statue replaced"); T.ok(not S.created[3].removed)
end)

T.case("LC statue: no target in range -> slots skipped, no burst later", function()
  local S = Stub.install()
  local Magic = require("rift.engine.lc_magic")
  Magic.owners, Magic.statues, Magic.by_id = {}, {}, {}
  local lc = S.hero("npc_dota_hero_legion_commander", 0, 2, Vector(0, 0, 0), {})
  local foe = S.hero("npc_dota_hero_axe", 1, 3, Vector(5000, 0, 0), {})
  Magic.summon(lc, S.ability(1), Vector(0, 0, 0), 1)
  S.advance(7)
  T.eq(#S.projectiles, 0)
  foe.pos = Vector(200, 0, 0)
  S.advance(3)
  T.eq(#S.projectiles, 1, "only the remaining slot fires")
end)

T.case("LC magical: spell amp follows rank, earned points and Break", function()
  local S = Stub.install()
  local Magic = require("rift.engine.lc_magic")
  Magic.owners = {}
  local lc = S.hero("npc_dota_hero_legion_commander", 0, 2, Vector(0, 0, 0), {})
  T.eq(Magic.spell_amp(lc), 0, "no ultimate")
  lc.abilities.lc_duel_magical = S.ability(1)
  T.eq(Magic.spell_amp(lc), 3)
  local gm = { upgrades = { DirectionId = function(_, pid) return pid == 0 and "lc_duel_magical" or "x" end } }
  Magic.on_hero_death(gm, { killer = 0, multiplier = 1, assists = { { pid = 1 } } }, "tok")
  Magic.on_hero_death(gm, { killer = 0, multiplier = 1, assists = {} }, "tok") -- same death again
  T.eq(Magic.spell_amp(lc), 4)
  T.eq(Magic.owner_state(1).earned, 0, "other directions earn nothing")
  lc.broken = true
  T.eq(Magic.spell_amp(lc), 0)
end)
