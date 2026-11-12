-- TA magical R: choose an enemy hero; after a visible delay a trap blast erupts at
-- the target's position AT CAST (does not follow). Magic damage + slow only
-- (trap_debuff_policy in hero_balance). Spell block cancels the cast entirely.
local B = require("rift.data.hero_balance").ta
ta_psionic_blast = ta_psionic_blast or ((type(class) == "function") and class({}) or {})
local function r(l) return math.max(1, math.min(3, l)) end
function ta_psionic_blast:GetCooldown(l) return B.trap_magical.cooldown[r(l + 1)] end
function ta_psionic_blast:GetManaCost() return B.trap_magical.mana end
function ta_psionic_blast:GetCastRange() return B.trap_magical.cast_range end
function ta_psionic_blast:GetAOERadius() return B.trap_magical.radius end
function ta_psionic_blast:OnSpellStart()
  local c, target = self:GetCaster(), self:GetCursorTarget()
  if not target or target:IsNull() then return end
  if target.TriggerSpellAbsorb and target:TriggerSpellAbsorb(self) then return end
  local cfg = B.trap_magical
  local pos = target:GetAbsOrigin()
  local level = r(self:GetLevel())
  local fx = ParticleManager:CreateParticle(B.trap_telegraph_particle, PATTACH_WORLDORIGIN, nil)
  ParticleManager:SetParticleControl(fx, 0, pos)
  EmitSoundOnLocationWithCaster(pos, "Hero_TemplarAssassin.Trap", c)
  local ability = self
  c:SetContextThink("rift_ta_blast_" .. tostring(GameRules:GetGameTime()), function()
    ParticleManager:DestroyParticle(fx, false)
    ParticleManager:ReleaseParticleIndex(fx)
    if ability:IsNull() or c:IsNull() then return nil end
    local hits = FindUnitsInRadius(c:GetTeamNumber(), pos, nil, cfg.radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
    for _, e in ipairs(hits) do
      ApplyDamage({ victim = e, attacker = c, damage = cfg.damage[level], damage_type = DAMAGE_TYPE_MAGICAL, ability = ability })
      if e:IsAlive() then
        require("rift.engine.mods").add(e, c, ability, "modifier_rift_ta_trap_slow",
          { duration = cfg.slow_duration, slow = cfg.slow[level] })
      end
    end
    EmitSoundOnLocationWithCaster(pos, "Hero_TemplarAssassin.Trap.Explode", c)
    return nil
  end, cfg.delay)
end
