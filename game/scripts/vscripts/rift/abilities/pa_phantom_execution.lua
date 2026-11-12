-- PA physical ultimate "Phantom Execution": a visible spirit flies to the enemy; on
-- arrival it deals ONE guaranteed critical physical hit on behalf of PA (PA does not
-- move). Not an attack: no item procs, no second crit roll, item crits do not
-- multiply it. Dodgeable; no hit if the target is dead/invulnerable/blocks the spell.
-- Native Coup de Grace stays leveled (hidden) so normal attacks keep their crits.
-- Rules: core/heroes/pa_physical. Numbers: hero_balance.
local B = require("rift.data.hero_balance").pa.execution_physical
local Exec = require("rift.core.heroes.pa_physical")
local NATIVE = "phantom_assassin_coup_de_grace"

pa_phantom_execution = pa_phantom_execution or ((type(class) == "function") and class({}) or {})

local function r(l) return math.max(1, math.min(3, l)) end

-- Upgrade "pa_spirit_haste" shortens the cooldown (server value; the client tooltip shows the base).
function pa_phantom_execution:GetCooldown(l)
  local cut = require("rift.engine.build_bonus").get(self:GetCaster(), "spirit_cooldown_reduction")
  return math.max(1, B.cooldown[r(l + 1)] - cut)
end
function pa_phantom_execution:GetManaCost(l) return B.mana[r(l + 1)] end
function pa_phantom_execution:GetCastRange() return B.range end

-- Keep the hidden native at the same rank: its passive crit must grow with the ultimate.
function pa_phantom_execution:OnUpgrade()
  if not IsServer() then return end
  local n = self:GetCaster():FindAbilityByName(NATIVE)
  if n and n:GetLevel() ~= self:GetLevel() then n:SetLevel(self:GetLevel()) end
end

function pa_phantom_execution:OnSpellStart()
  local c, target = self:GetCaster(), self:GetCursorTarget()
  if not target or target:IsNull() then return end
  local n = c:FindAbilityByName(NATIVE)
  local rank = r(self:GetLevel())
  local crit = Exec.crit_percent(n and n:GetSpecialValueFor("crit_bonus") or 0, rank, B.crit_fallback)
  local spirit = self:SpawnSpirit(c, target)
  ProjectileManager:CreateTrackingProjectile({
    Target = target, Source = c, Ability = self, EffectName = spirit and "" or B.spirit_particle,
    iMoveSpeed = B.speed, bDodgeable = true, bProvidesVision = false,
    iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
    ExtraData = { crit = crit, spirit = spirit and spirit:entindex() or -1 },
  })
  EmitSoundOn("Hero_PhantomAssassin.Strike.Start", c)
end

-- Visual spirit: flies to the target at the projectile's speed. Hit logic stays in the
-- projectile (dodge, spell block); the unit is removed when the projectile ends.
function pa_phantom_execution:SpawnSpirit(c, target)
  local u = CreateUnitByName(B.spirit_unit, c:GetAbsOrigin(), false, c, c, c:GetTeamNumber())
  if not u then return nil end
  require("rift.engine.mods").add(u, c, self, "modifier_rift_pa_spirit", {})
  local dt, deadline = 0.03, GameRules:GetGameTime() + B.range / B.speed * 3 + 2
  u:SetContextThink("rift_pa_spirit_fly", function()
    if u:IsNull() then return nil end
    if target:IsNull() or GameRules:GetGameTime() > deadline then UTIL_Remove(u); return nil end
    local pos, goal = u:GetAbsOrigin(), target:GetAbsOrigin()
    local d = goal - pos
    d.z = 0
    local len = d:Length2D()
    if len > 1 then
      local dir = d / len
      u:SetForwardVector(dir)
      local np = pos + dir * math.min(len, B.speed * dt)
      u:SetAbsOrigin(Vector(np.x, np.y, GetGroundHeight(np, u) + 60))
    end
    return dt
  end, 0)
  return u
end

function pa_phantom_execution:OnProjectileHit_ExtraData(target, _, data)
  local c = self:GetCaster()
  local spirit = tonumber(data.spirit) and tonumber(data.spirit) >= 0 and EntIndexToHScript(tonumber(data.spirit)) or nil
  if spirit and not spirit:IsNull() then UTIL_Remove(spirit) end
  if not c or c:IsNull() then return true end
  local exists = target ~= nil and not target:IsNull()
  local ok = Exec.can_hit({
    exists = exists, alive = exists and target:IsAlive(),
    invulnerable = exists and target:IsInvulnerable(),
    absorbed = exists and target:IsAlive() and target.TriggerSpellAbsorb and target:TriggerSpellAbsorb(self) or false,
  })
  if not ok then return true end
  local dmg = Exec.hit_damage(c:GetAverageTrueAttackDamage(target), tonumber(data.crit) or B.crit_fallback[1])
  local dealt = ApplyDamage({ victim = target, attacker = c, damage = dmg, damage_type = DAMAGE_TYPE_PHYSICAL,
    damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, ability = self })
  SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, target, dealt or dmg, nil)
  EmitSoundOn("Hero_PhantomAssassin.CoupDeGrace", target)
  require("rift.engine.log").debug("PA", string.format("execution hit raw=%.0f dealt=%.0f crit=%s", dmg, dealt or -1,
    tostring(data.crit)))
  return true
end
