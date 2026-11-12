-- PA magical Q "Stifling Dagger": the native dagger effects (reduced attack + base
-- damage, slow) on up to 2 different targets per cast: the chosen one and one extra
-- enemy near it (hero first). One mana cost and one cooldown per cast; the extra
-- dagger never recurses. One server roll per cast: on success, when BOTH daggers of
-- the cast hit, each of the two targets takes chain lightning magic damage once.
-- Rules: core/pa_storm_daggers. Numbers: native Stifling Dagger (hidden, same level,
-- talents included) with hero_balance fallbacks. The +2 daggers talent adds nothing
-- here (owner cap: 2 targets per cast).
local B = require("rift.data.hero_balance").pa.storm_magical
local Storm = require("rift.core.pa_storm_daggers")
local NATIVE = "phantom_assassin_stifling_dagger"

pa_storm_dagger = pa_storm_dagger or ((type(class) == "function") and class({}) or {})

local function r(l) return math.max(1, math.min(4, l)) end

local function native(self)
  local c = self:GetCaster()
  return c and c.FindAbilityByName and c:FindAbilityByName(NATIVE) or nil
end

-- Method on the native (client-safe); nil when unavailable or zero.
local function ncall(self, method, ...)
  local n = native(self)
  if not n or not n[method] then return nil end
  local ok, v = pcall(n[method], n, ...)
  if ok and type(v) == "number" and v ~= 0 then return v end
  return nil
end

local function nval(self, key, fallback)
  local n = native(self)
  if n and n:GetLevel() > 0 then
    local v = n:GetSpecialValueFor(key)
    if type(v) == "number" and v ~= 0 then return v end
  end
  return fallback
end

function pa_storm_dagger:GetCooldown(l) return ncall(self, "GetCooldown", l) or B.dagger_cooldown end
function pa_storm_dagger:GetManaCost(l) return ncall(self, "GetManaCost", l) or B.dagger_mana end
function pa_storm_dagger:GetCastRange() return B.dagger_range[r(self:GetLevel())] end

function pa_storm_dagger:OnUpgrade()
  if not IsServer() then return end
  local n = native(self)
  if n and n:GetLevel() ~= self:GetLevel() then n:SetLevel(self:GetLevel()) end
end

local function launch(self, caster, target, cast_id)
  ProjectileManager:CreateTrackingProjectile({
    Target = target, Source = caster, Ability = self, EffectName = B.dagger_particle,
    iMoveSpeed = nval(self, "dagger_speed", B.dagger_speed), bDodgeable = true, bProvidesVision = false,
    iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
    ExtraData = { cast_id = cast_id, tid = target:entindex() },
  })
end

function pa_storm_dagger:OnSpellStart()
  local c, target = self:GetCaster(), self:GetCursorTarget()
  if not target or target:IsNull() then return end
  local store = require("rift.engine.pa_storm").store()
  local now = GameRules:GetGameTime()
  store:cleanup(now)
  local found = FindUnitsInRadius(c:GetTeamNumber(), target:GetAbsOrigin(), nil, B.second_target_radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_ANY_ORDER, false)
  local cands = {}
  for _, e in ipairs(found) do
    local p = e:GetAbsOrigin()
    table.insert(cands, { id = e:entindex(), x = p.x, y = p.y, is_hero = e:IsRealHero() })
  end
  local tp = target:GetAbsOrigin()
  local sid = Storm.pick_secondary(target:entindex(), { x = tp.x, y = tp.y }, cands, B.second_target_radius)
  local second = sid and EntIndexToHScript(sid) or nil
  local ult = c:FindAbilityByName("pa_storm_charge")
  local Bonus = require("rift.engine.build_bonus")
  local values = Storm.values_at(B, ult and ult:GetLevel() or 1, {
    chain_damage = Bonus.get(c, "chain_damage_bonus"), chain_chance = Bonus.get(c, "chain_chance_bonus_pct") / 100 })
  local cast_id, proc = store:begin_cast(c:entindex(), target:entindex(), second and sid or nil, values, now)
  launch(self, c, target, cast_id)
  if second then launch(self, c, second, cast_id) end
  EmitSoundOn("Hero_PhantomAssassin.Dagger.Cast", c)
  require("rift.engine.log").debug("PA", string.format("storm cast=%d targets=%d proc=%s", cast_id, second and 2 or 1,
    tostring(proc)))
end

local function dagger_effects(self, c, target)
  local rank = r(self:GetLevel())
  local base = nval(self, "base_damage", B.dagger_base_damage[rank])
  local factor = nval(self, "attack_factor", B.dagger_attack_factor[rank])
  local Mods = require("rift.engine.mods")
  -- Explicit physical damage with the native dagger formula. (OP-023: a PerformAttack with a
  -- temporary damage modifier did not change the attack's damage.) No native crit: Coup de Grace
  -- is at level 0 in this direction. Attack effects of items are not applied by the dagger.
  local raw = base + c:GetAverageTrueAttackDamage(target) * (100 + factor) / 100
  local dealt = ApplyDamage({ victim = target, attacker = c, damage_type = DAMAGE_TYPE_PHYSICAL, ability = self,
    damage = raw, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION })
  require("rift.engine.log").debug("PA", string.format("dagger hit raw=%.0f dealt=%.0f base=%s factor=%s", raw,
    dealt or -1, tostring(base), tostring(factor)))
  if target:IsAlive() and not target:IsMagicImmune() then
    local dur = nval(self, "duration", B.dagger_slow_duration[rank])
    if target.GetStatusResistance then dur = dur * (1 - target:GetStatusResistance()) end
    Mods.add(target, c, self, "modifier_rift_pa_dagger_slow",
      { duration = dur, slow = -nval(self, "move_slow", B.dagger_slow) })
  end
  EmitSoundOn("Hero_PhantomAssassin.Dagger.Target", target)
end

function pa_storm_dagger:OnProjectileHit_ExtraData(target, _, data)
  local c = self:GetCaster()
  if not c or c:IsNull() then return true end
  local valid = target ~= nil and not target:IsNull() and target:IsAlive() and not target:IsInvulnerable()
  if valid and target.TriggerSpellAbsorb and target:TriggerSpellAbsorb(self) then valid = false end
  if valid then dagger_effects(self, c, target) end
  local chain = require("rift.engine.pa_storm").store():on_hit(tonumber(data.cast_id), tonumber(data.tid), valid,
    GameRules:GetGameTime())
  if not chain then return true end
  local a, b = EntIndexToHScript(chain.targets[1]), EntIndexToHScript(chain.targets[2])
  if a and b and not a:IsNull() and not b:IsNull() then
    local fx = ParticleManager:CreateParticle(B.chain_particle, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(fx, 0, a:GetAbsOrigin() + Vector(0, 0, 100))
    ParticleManager:SetParticleControl(fx, 1, b:GetAbsOrigin() + Vector(0, 0, 100))
    ParticleManager:ReleaseParticleIndex(fx)
    EmitSoundOn("Item.Maelstrom.Chain_Lightning.Jump", b)
  end
  for _, e in ipairs({ a, b }) do
    if e and not e:IsNull() and e:IsAlive() then
      ApplyDamage({ victim = e, attacker = c, damage = chain.damage, damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
    end
  end
  require("rift.engine.log").info("PA", string.format("storm chain cast=%d damage=%d", chain.cast_id, chain.damage))
  return true
end
