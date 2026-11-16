-- Server-owned, bounded sessions for the alpha roster. No attacks are fabricated:
-- physical spell hits do not proc items, crits, cleave or attack lifesteal.
local E = require("rift.data.expansion")
local Math = require("rift.core.path_math")
local Mods = require("rift.engine.mods")
local Area = require("rift.engine.area")
local M = {}
local serial = 0
local flying = {}
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
    intellect = c:GetIntellect(false), agility = c:GetAgility(), attack_speed=c:GetDisplayAttackSpeed() }
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
  -- Native impact systems can spawn from a different CP than their controller.
  if d.effect_origin_cp then ParticleManager:SetParticleControl(p,d.effect_origin_cp,pos) end
  if d.radius then ParticleManager:SetParticleControl(p, 2, Vector(d.radius, 0, 0)) end
  timer(function()
    ParticleManager:DestroyParticle(p, false)
    ParticleManager:ReleaseParticleIndex(p)
  end, lifetime or 1)
end
local function debuff(s, u, name, duration)
  if immune(u) then return end
  local passive=s.caster:FindAbilityByName("rift_sven_mystic_cleave")
  if passive and passive:GetLevel()>0 and not s.caster:PassivesDisabled() then
    -- Native spells consume STATUS_RESISTANCE_CASTER themselves. Raw Lua
    -- AddNewModifier does not (confirmed in Tools); apply it here exactly once.
    duration=duration*(1+require("rift.data.hero_balance").passives.sven_debuff[passive:GetLevel()]/100)
  end
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
    local inside = not d.heal_inside or (c:GetAbsOrigin() - s.point):Length2D() <= s.radius
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
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, FIND_CLOSEST, false)
end
local function launch_line(s,tick,origin,direction)
  serial=serial+1
  local id=serial
  local shot={};for k,v in pairs(s) do shot[k]=v end
  shot.linear=true;shot.seen={};shot.tick=tick;shot.origin=origin;shot.direction=direction
  flying[id]=shot
  local projectile=ProjectileManager:CreateLinearProjectile({Ability=s.ability,Source=s.caster,EffectName=s.def.particle,
    vSpawnOrigin=origin+Vector(0,0,64),vVelocity=direction*s.def.projectile_speed,
    fDistance=s.def.range,fStartRadius=s.radius,fEndRadius=s.radius,bDeleteOnHit=false,
    iUnitTargetTeam=DOTA_UNIT_TARGET_TEAM_ENEMY,iUnitTargetType=DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC,
    iUnitTargetFlags=s.def.path=="physical" and DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES or 0,
    fExpireTime=GameRules:GetGameTime()+s.def.range/s.def.projectile_speed+1,
    bProvidesVision=false,ExtraData={rift_path=id}})
  require("rift.engine.log").debug("PROJECTILE","launched "..s.def.id.." id="..id.." native="..tostring(projectile))
  timer(function()flying[id]=nil end,s.def.range/s.def.projectile_speed+1)
end
function M.pulse(s, tick)
  local d, c = s.def, s.caster
  s.healed = 0
  if d.mode == "orbit" and not s.death_point then
    s.point = c:GetAbsOrigin()
    if not c:IsAlive() then s.death_point = s.point end
  end
  local pos = s.death_point or s.point
  local radius = s.radius + (d.expand or 0) * (tick - 1)
  local origin = s.origin
  if d.mode == "line" then launch_line(s,tick,origin,s.direction);return end
  M.effect(d, pos + Vector(0,0,64), nil, d.interval)
  for _, u in ipairs(units(s, pos, radius)) do
    local inside, distance = true, 0
    if d.mode == "line" then
      inside, distance = Math.in_line(u:GetAbsOrigin(), origin, s.direction, d.range, s.radius)
    end
    if inside then hit(s, u, Math.damage(d, s.rank, s.stats, tick, distance), tick) end
  end
end
function M.stance_attack(mod, ev)
  local c, a = mod:GetParent(), mod:GetAbility()
  if not valid(c) or ev.attacker ~= c or not a or a:IsNull() or c:IsIllusion() or not open() then return end
  local d = E.abilities[a:GetAbilityName()]
  -- OnAttackLanded can arrive after the attack killed its primary victim. It
  -- must still count toward the stance and hit surviving nearby enemies.
  local target=ev.target
  if not d or not target or target:IsNull() or not target:IsHero()
    or target:GetTeamNumber()==c:GetTeamNumber() or target:IsInvulnerable() then return end
  mod.hits = (mod.hits or 0) + 1
  mod:SetStackCount(mod.hits % d.every)
  if mod.hits % d.every ~= 0 then return end
  local s = { caster = c, ability = a, def = d, rank = mod.rank or a:GetLevel(), stats = mod.stats,
    point = ev.target:GetAbsOrigin(), radius = Area.radius(c, d.radius) }
  local origin = c:GetAbsOrigin()
  local direction = (s.point - origin):Normalized()
  if d.line then
    EmitSoundOn(d.sound,c);launch_line(s,1,origin,direction);return
  end
  local pos, radius = s.point, s.radius
  if d.line then pos, radius = origin, d.range + s.radius end
  M.effect(d, origin + Vector(0,0,64), (d.line and origin + direction * d.range or s.point) + Vector(0,0,64))
  if d.wave_particle then M.effect({particle=d.wave_particle,radius=s.radius,effect_origin_cp=d.wave_origin_cp},s.point+Vector(0,0,24),nil,.55) end
  EmitSoundOn(d.sound, c)
  for _, u in ipairs(units(s, pos, radius)) do
    if not d.line or Math.in_line(u:GetAbsOrigin(), origin, direction, d.range, s.radius) then
      hit(s, u, Math.damage(d, s.rank, s.stats), 1)
    end
  end
end
function M.projectile_hit(target, data)
  local id = tonumber(data and data.rift_path)
  local s = id and flying[id]
  if s and s.linear then
    require("rift.engine.log").debug("PROJECTILE","collision id="..id.." target="..tostring(target and target:GetUnitName()))
    if not target then flying[id]=nil;return false end
    if s.seen[target] then return false end
    s.seen[target]=true
    if not s.caster:IsNull() and not s.ability:IsNull() and open() then
      local _,distance=Math.in_line(target:GetAbsOrigin(),s.origin,s.direction,s.def.range,s.radius)
      hit(s,target,Math.damage(s.def,s.rank,s.stats,s.tick,distance),s.tick)
    end
    return false
  end
  flying[id or -1] = nil
  if s and valid(s.caster) and not s.ability:IsNull() and open() and target == s.target then
    hit(s, target, Math.damage(s.def, s.rank, s.stats), 1)
  end
  return true
end
local function barrage(s)
  -- Each volley searches the whole circle around CM, including behind her.
  s.point=s.caster:GetAbsOrigin()
  for _, u in ipairs(units(s, s.point, s.radius, true)) do
    serial = serial + 1
    local id = serial
    local shot = {}; for k,v in pairs(s) do shot[k]=v end; shot.target = u
    flying[id] = shot
    ProjectileManager:CreateTrackingProjectile({ Target=u, Source=s.caster, Ability=s.ability,
      EffectName=s.def.particle, iMoveSpeed=1100, bDodgeable=true, bProvidesVision=false,
      iSourceAttachment=DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, ExtraData={rift_path=id} })
    timer(function() flying[id]=nil end, 5)
  end
end
local function tether_effect(s)
  local p=ParticleManager:CreateParticle(s.def.particle,PATTACH_WORLDORIGIN,s.caster)
  local deadline=GameRules:GetGameTime()+s.def.ticks*s.def.interval+1
  timer(function()
    if s.ended or not valid(s.caster) or not enemy(s.caster,s.target,s.def) or not open()
      or GameRules:GetGameTime()>deadline or (s.target:GetAbsOrigin()-s.caster:GetAbsOrigin()):Length2D()>s.def.leash then
      s.ended=true;ParticleManager:DestroyParticle(p,false);ParticleManager:ReleaseParticleIndex(p);return nil
    end
    ParticleManager:SetParticleControl(p,0,s.caster:GetAbsOrigin()+Vector(0,0,64))
    ParticleManager:SetParticleControl(p,1,s.target:GetAbsOrigin()+Vector(0,0,64))
    return .03
  end,0)
end
local function sleight(s)
  local c, a, d = s.caster, s.ability, s.def
  local targets = units(s, s.point, s.radius, true)
  if #targets == 0 then return end
  local mod = Mods.add(c,c,a,"modifier_rift_sleight",{duration=d.max_targets*d.interval+0.5})
  local i = 0
  local function finish()
    if not c:IsNull() then
      if mod then mod:Destroy() end
      FindClearSpaceForUnit(c,s.origin,true)
    end
  end
  timer(function()
    if not valid(c) or a:IsNull() or not open() then finish(); return nil end
    i = i + 1
    local u = targets[i]
    if not u or i > d.max_targets then finish(); return nil end
    if enemy(c,u,d) and (u:GetAbsOrigin()-s.point):Length2D() <= s.radius then
      FindClearSpaceForUnit(c,u:GetAbsOrigin()-s.direction*100,true)
      c:StartGesture(ACT_DOTA_ATTACK)
      M.effect(d,u:GetAbsOrigin(),nil,d.interval)
      -- Real attacks: evasion and attack/item procs follow the normal engine path.
      c:PerformAttack(u,true,true,true,true,false,false,false)
    end
    return d.interval
  end,0)
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
  local range=d.range>0 and d.range+c:GetCastRangeBonus() or 0
  local point = Math.clamp_point(aim, origin, range)
  local s = { caster = c, ability = a, def = d, rank = a:GetLevel(), stats = M.snapshot(c),
    origin = origin, point = Vector(point.x, point.y, point.z), target = target, radius=Area.radius(c,d.radius) }
  s.direction = (s.point - origin):Length2D() > 1 and (s.point - origin):Normalized() or c:GetForwardVector()
  EmitSoundOn(d.sound, c)
  if d.mode == "sleight" then sleight(s); return end
  if d.mode == "pull" then
    M.effect(d,origin)
    for _,u in ipairs(units(s,origin,s.radius)) do
      local delta=origin-u:GetAbsOrigin()
      if not immune(u) and delta:Length2D()>100 then
        Mods.add(u,c,a,"modifier_rift_axe_pull",{duration=require("rift.data.hero_balance").axe.pull_duration,
          x=origin.x,y=origin.y,z=origin.z,distance=d.pull_distance})
      end
      hit(s,u,Math.damage(d,s.rank,s.stats),1)
    end
    return
  end
  if d.mode == "stance" then
    local mod = Mods.add(c, c, a, "modifier_rift_path_stance", { duration = d.duration })
    if mod then mod.stats, mod.hits = s.stats, 0 end
    return
  end
  -- Delayed spells reveal their impact area before damage. Native ping is a
  -- fallback telegraph; particle appearance must still be reviewed in Tools.
  if d.delay then
    M.effect({ particle = "particles/ui_mouseactions/ping_world.vpcf" }, s.point, nil, d.delay)
  end
  local tick = 0
  if d.mode=="tether" then tether_effect(s) end
  timer(function()
    if s.ended or c:IsNull() or (not c:IsAlive() and not d.persists_death) or a:IsNull() or not open() then
      s.ended=true
      if not c:IsNull() then StopSoundOn(d.sound, c) end
      return nil
    end
    tick = tick + 1
    if d.mode == "barrage" then barrage(s)
    elseif d.mode == "tether" then
      if not enemy(c, target, d) or (target:GetAbsOrigin() - c:GetAbsOrigin()):Length2D() > d.leash then
        s.ended=true;StopSoundOn(d.sound, c); return nil
      end
      s.healed = 0
      hit(s, target, Math.damage(d, s.rank, s.stats, tick), tick)
    else
      M.pulse(s, tick)
    end
    if tick < d.ticks then return d.interval end
    s.ended=true
    StopSoundOn(d.sound, c)
    return nil
  end, d.delay or 0)
end
return M
