-- Server-owned, bounded sessions for the alpha roster. No attacks are fabricated:
-- physical spell hits do not proc items, crits, cleave or attack lifesteal.
local E = require("rift.data.expansion")
local Math = require("rift.core.path_math")
local Mods = require("rift.engine.mods")
local M = {}
local serial = 0
local function valid(u) return u and not u:IsNull() and u:IsAlive() end
local function open()
  local gm = GameRules.RiftArena
  return not gm or gm.director.state:rewards_open()
end
local function immune(u) return u:IsMagicImmune() or u:IsDebuffImmune() end
local function enemy(c, u, d)
  return valid(u) and u:GetTeamNumber() ~= c:GetTeamNumber() and not u:IsInvulnerable()
    and (d.path == "physical" or not immune(u))
end
function M.snapshot(c)
  return { attack = c:GetAverageTrueAttackDamage(nil), strength = c:GetStrength(),
    intellect = c:GetIntellect(false), agility = c:GetAgility() }
end
local function timer(fn, delay)
  serial = serial + 1
  GameRules:GetGameModeEntity():SetContextThink("rift_path_" .. serial, fn, delay or 0)
end
-- All effects are explicitly destroyed, including persistent native particle systems.
function M.effect(d, pos, finish, lifetime)
  local p = ParticleManager:CreateParticle(d.particle, PATTACH_WORLDORIGIN, nil)
  ParticleManager:SetParticleControl(p, 0, pos)
  ParticleManager:SetParticleControl(p, 1, finish or pos)
  timer(function()
    ParticleManager:DestroyParticle(p, false)
    ParticleManager:ReleaseParticleIndex(p)
  end, lifetime or 1)
end
local function debuff(s, u, name, duration)
  if immune(u) then return end
  Mods.add(u, s.caster, s.ability, name, { duration = duration * (1 - u:GetStatusResistance()) })
end
local function hit(s, u, amount, tick)
  local c, d = s.caster, s.def
  if not enemy(c, u, d) then return 0 end
  local dealt = ApplyDamage({ victim = u, attacker = c, ability = s.ability, damage = amount,
    damage_type = d.path == "physical" and DAMAGE_TYPE_PHYSICAL or DAMAGE_TYPE_MAGICAL,
    damage_flags = d.path == "physical" and DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION or 0 }) or 0
  if valid(u) then
    if d.slow then debuff(s, u, "modifier_rift_path_slow", (d.interval or 0.5) + 0.35) end
    if d.stun and tick == 1 then debuff(s, u, "modifier_stunned", d.stun) end
    if d.root and (not d.root_every or tick % d.root_every == 0) then
      debuff(s, u, "modifier_rift_path_root", d.root)
    end
  end
  if d.heal_fraction and dealt > 0 and u:IsRealHero() and not u:IsIllusion() then
    local inside = not d.heal_inside or (c:GetAbsOrigin() - s.point):Length2D() <= d.radius
    if inside then
      -- Per-session cap per tick across ALL victims: FFA does not multiply sustain.
      local heal = math.min(dealt * d.heal_fraction, math.max(0, c:GetMaxHealth() * d.heal_cap - (s.healed or 0)))
      c:Heal(heal, s.ability)
      s.healed = (s.healed or 0) + heal
    end
  end
  return dealt
end
local function units(s, pos, radius, visible)
  local flags = s.def.path == "physical" and DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES or 0
  if visible then flags = flags + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS end
  return FindUnitsInRadius(s.caster:GetTeamNumber(), pos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO, flags, FIND_CLOSEST, false)
end
function M.pulse(s, tick)
  local d, c = s.def, s.caster
  s.healed = 0
  local pos = d.mode == "orbit" and c:GetAbsOrigin() or s.point
  local radius = d.radius + (d.expand or 0) * (tick - 1)
  local origin = s.origin
  if d.mode == "line" then pos, radius = origin, d.range + d.radius end
  M.effect(d, pos, d.mode == "line" and origin + s.direction * d.range or nil, d.interval)
  for _, u in ipairs(units(s, pos, radius)) do
    local inside, distance = true, 0
    if d.mode == "line" then
      inside, distance = Math.in_line(u:GetAbsOrigin(), origin, s.direction, d.range, d.radius)
    end
    if inside then hit(s, u, Math.damage(d, s.rank, s.stats, tick, distance), tick) end
  end
end
function M.stance_attack(mod, ev)
  local c, a = mod:GetParent(), mod:GetAbility()
  if not valid(c) or ev.attacker ~= c or not a or a:IsNull() or c:IsIllusion() or not open() then return end
  local d = E.abilities[a:GetAbilityName()]
  if not d or not enemy(c, ev.target, d) or not ev.target:IsHero() then return end
  mod.hits = (mod.hits or 0) + 1
  mod:SetStackCount(mod.hits % d.every)
  if mod.hits % d.every ~= 0 then return end
  local s = { caster = c, ability = a, def = d, rank = a:GetLevel(), stats = mod.stats,
    point = ev.target:GetAbsOrigin() }
  local origin = c:GetAbsOrigin()
  local direction = (s.point - origin):Normalized()
  local pos, radius = s.point, d.radius
  if d.line then pos, radius = origin, d.range + d.radius end
  M.effect(d, origin, d.line and origin + direction * d.range or s.point)
  EmitSoundOn(d.sound, c)
  for _, u in ipairs(units(s, pos, radius)) do
    if not d.line or Math.in_line(u:GetAbsOrigin(), origin, direction, d.range, d.radius) then
      hit(s, u, Math.damage(d, s.rank, s.stats), 1)
    end
  end
end
function M.cast(a, d)
  local c = a:GetCaster()
  if not valid(c) or c:IsIllusion() or not open() then return end
  local target = d.target == "unit" and a:GetCursorTarget() or nil
  if d.target == "unit" then
    if not enemy(c, target, d) or not target:IsHero() then return end
    if target:TriggerSpellAbsorb(a) then return end
  end
  local origin = c:GetAbsOrigin()
  local aim = d.target == "point" and a:GetCursorPosition() or (target and target:GetAbsOrigin() or origin)
  local point = Math.clamp_point(aim, origin, d.range)
  local s = { caster = c, ability = a, def = d, rank = a:GetLevel(), stats = M.snapshot(c),
    origin = origin, point = Vector(point.x, point.y, point.z), target = target }
  s.direction = (s.point - origin):Length2D() > 1 and (s.point - origin):Normalized() or c:GetForwardVector()
  EmitSoundOn(d.sound, c)
  if d.mode == "stance" then
    local mod = Mods.add(c, c, a, "modifier_rift_path_stance", { duration = d.duration })
    if mod then mod.stats, mod.hits = s.stats, 0 end
    return
  end
  if d.mode == "verdict" then
    local amount = Math.damage(d, s.rank, s.stats) + (target:GetMaxHealth() - target:GetHealth()) * d.missing_health
    local impact = target:GetAbsOrigin()
    local real_target = target:IsRealHero() and not target:IsIllusion()
    M.effect(d, impact)
    hit(s, target, amount, 1)
    for _, u in ipairs(units(s, impact, d.radius)) do
      if u ~= target then hit(s, u, amount * d.cleave, 1) end
    end
    if real_target and (target:IsNull() or not target:IsAlive()) then
      local remaining = a:GetCooldownTimeRemaining()
      a:EndCooldown(); a:StartCooldown(remaining * (1 - d.kill_refund))
    end
    return
  end
  -- Delayed spells reveal their impact area before damage. Native ping is a
  -- fallback telegraph; particle appearance must still be reviewed in Tools.
  if d.delay then
    M.effect({ particle = "particles/ui_mouseactions/ping_world.vpcf" }, s.point, nil, d.delay)
  end
  local tick = 0
  timer(function()
    if not valid(c) or a:IsNull() or not open() then
      if not c:IsNull() then StopSoundOn(d.sound, c) end
      return nil
    end
    tick = tick + 1
    if d.mode == "tether" then
      if not enemy(c, target, d) or (target:GetAbsOrigin() - c:GetAbsOrigin()):Length2D() > d.leash then
        StopSoundOn(d.sound, c); return nil
      end
      s.healed = 0
      M.effect(d, target:GetAbsOrigin(), c:GetAbsOrigin(), d.interval)
      hit(s, target, Math.damage(d, s.rank, s.stats, tick), tick)
    elseif d.mode == "volley" then
      -- Bounce only through visible enemies inside the original cast's leash.
      -- Never grants invulnerability: disarm/stun stops this attack sequence.
      if c:IsStunned() or c:IsDisarmed() then StopSoundOn(d.sound, c); return nil end
      local next_target
      for _, u in ipairs(units(s, c:GetAbsOrigin(), d.leash, true)) do
        if enemy(c, u, d) and (u:GetAbsOrigin() - origin):Length2D() <= d.leash then
          if u ~= s.last then next_target = u; break end
          next_target = next_target or u
        end
      end
      if tick == 1 and enemy(c, target, d) then next_target = target end
      if not next_target then StopSoundOn(d.sound, c); return nil end
      if d.jump then FindClearSpaceForUnit(c, next_target:GetAbsOrigin() - s.direction * 100, true) end
      s.last = next_target
      M.effect(d, next_target:GetAbsOrigin(), nil, d.interval)
      hit(s, next_target, Math.damage(d, s.rank, s.stats, tick), tick)
    else
      M.pulse(s, tick)
    end
    if tick < d.ticks then return d.interval end
    StopSoundOn(d.sound, c)
    return nil
  end, d.delay or 0)
end
return M
