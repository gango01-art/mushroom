-- Shared directed Psi wave for TA magical Q/W/E: magic damage, pierces, one hit
-- per wave per victim life, no attack record (no crit/bash/on-hit), spell amp once
-- (ApplyDamage without NO_SPELL_AMPLIFICATION). Intellect scaling snapshotted at
-- release (core/heroes/ta_magical). Waves ignore terrain, same for all three skills.
local B = require("rift.data.hero_balance").ta
local Waves = require("rift.core.heroes.ta_magical")

local M = {}
M.store = M.store or Waves.new()

local function intellect(caster)
  if not caster.GetIntellect then return 0 end
  local ok, v = pcall(caster.GetIntellect, caster, false)
  if ok and type(v) == "number" then return v end
  ok, v = pcall(caster.GetIntellect, caster)
  return (ok and type(v) == "number") and v or 0
end

-- direction: Vector (normalized on XY). Returns wave_id.
function M.fire(caster, ability, origin, direction, base)
  local cfg = B.waves_magical
  local dir = Vector(direction.x, direction.y, 0)
  if dir:Length2D() < 0.01 then dir = caster:GetForwardVector() end
  dir = dir:Normalized()
  local now = GameRules:GetGameTime()
  local Bonus = require("rift.engine.build_bonus")
  base = base + Bonus.get(caster, "wave_damage_bonus")
  local length = cfg.length + Bonus.get(caster, "wave_length_bonus")
  local life = length / cfg.speed + 0.5
  local id, dmg = M.store:release(caster:entindex(), base, intellect(caster), cfg.intellect_scaling, now, life)
  ProjectileManager:CreateLinearProjectile({
    Ability = ability, EffectName = B.wave_particle, vSpawnOrigin = origin, fDistance = length,
    fStartRadius = Waves.half_width(cfg.width), fEndRadius = Waves.half_width(cfg.width), Source = caster,
    bHasFrontalCone = false, bReplaceExisting = false,
    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY, iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
    iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    fExpireTime = now + life, bDeleteOnHit = false, vVelocity = dir * cfg.speed, bProvidesVision = false,
    ExtraData = { wave_id = id },
  })
  M.store:cleanup(now)
  return id, dmg
end

-- Call from the ability's OnProjectileHit_ExtraData. Always returns false (pierce).
function M.hit(ability, target, extra)
  if not target or target:IsNull() or not extra or not extra.wave_id then return false end
  local gm = GameRules.RiftArena
  local key = (gm and gm.ids) and gm.ids:victim_key(target:entindex()) or tostring(target:entindex())
  local dmg = M.store:claim(tonumber(extra.wave_id), key, GameRules:GetGameTime())
  if dmg then
    ApplyDamage({ victim = target, attacker = ability:GetCaster(), damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL,
                  damage_flags = DOTA_DAMAGE_FLAG_NONE, ability = ability })
  end
  return false
end

return M
