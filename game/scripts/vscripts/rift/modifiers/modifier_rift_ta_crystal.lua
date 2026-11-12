-- Server state of a Psionic Crystal unit (TA physical). The crystal takes no real
-- damage: each landed attack spends one durability. An attack by its owner (TA main
-- hero) first emits one radial Psi Blades pulse, then spends durability. Enemy
-- attacks only spend durability. Owner illusions / other units are ignored.
-- Timer expiry or replacement: no pulse.
local B = require("rift.data.hero_balance").ta.crystal_physical
local Crystal = require("rift.core.heroes.ta_physical")

modifier_rift_ta_crystal = modifier_rift_ta_crystal or ((type(class) == "function") and class({}) or {})

function modifier_rift_ta_crystal:IsHidden() return true end
function modifier_rift_ta_crystal:IsPurgable() return false end

function modifier_rift_ta_crystal:OnCreated()
  if not IsServer() then return end
  local ability = self:GetAbility()
  self.owner = self:GetCaster()
  self.session = Crystal.new(B, math.max(1, ability and ability:GetLevel() or 1), GameRules:GetGameTime())
  local p = self:GetParent()
  p:SetBaseMaxHealth(B.durability)
  p:SetMaxHealth(B.durability)
  p:SetHealth(B.durability)
end

function modifier_rift_ta_crystal:CheckState()
  return { [MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end

function modifier_rift_ta_crystal:DeclareFunctions()
  return { MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL, MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
           MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE, MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_rift_ta_crystal:GetAbsoluteNoDamagePhysical() return 1 end
function modifier_rift_ta_crystal:GetAbsoluteNoDamageMagical() return 1 end
function modifier_rift_ta_crystal:GetAbsoluteNoDamagePure() return 1 end

local function classify(attacker, owner)
  if not attacker or attacker:IsNull() then return "other" end
  if attacker == owner then return "owner" end
  if attacker:GetTeamNumber() ~= owner:GetTeamNumber() then return "enemy" end
  return "other"  -- owner's illusions, summons, allies
end

function modifier_rift_ta_crystal:OnAttackLanded(params)
  if not IsServer() or params.target ~= self:GetParent() then return end
  local kind = classify(params.attacker, self.owner)
  local r = self.session:on_attacked(kind)
  if r.pulse_id then
    local gm = GameRules.RiftArena
    if gm and gm.MarkCrystalHit then gm:MarkCrystalHit(self.owner) end -- blocks native spill this frame
    self:Pulse(r.pulse_id, params.damage)
  end
  local p = self:GetParent()
  if r.destroyed then
    self.broken = true
    self:Destroy()
  else
    p:SetHealth(math.max(1, self.session.durability))
  end
end

function modifier_rift_ta_crystal:Pulse(pulse_id, source_damage)
  local owner = self.owner
  local psi = owner:FindAbilityByName("templar_assassin_psi_blades")
  if not psi or psi:GetLevel() < 1 then
    print("[RIFT][WARN][TA] crystal pulse skipped: Psi Blades not learned")
    return
  end
  local coef = psi:GetSpecialValueFor("attack_spill_pct") / 100
  -- VERIFY (OP-007/OP-013): params.damage = full attacking hit incl. Meld/Refraction/crit of THIS attack.
  local dmg = Crystal.pulse_damage(source_damage or 0, coef)
  local dtype = psi:GetAbilityDamageType()
  if not dtype or dtype == DAMAGE_TYPE_NONE then dtype = DAMAGE_TYPE_PURE end
  local gm = GameRules.RiftArena
  local origin = self:GetParent():GetAbsOrigin()
  local enemies = FindUnitsInRadius(owner:GetTeamNumber(), origin, nil, self.session:radius(),
    DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
  local hits = 0
  for _, e in ipairs(enemies) do
    if e:IsRealHero() and not e:IsIllusion() and e:IsAlive() then
      local key = gm and gm.ids and gm.ids:victim_key(e:entindex()) or tostring(e:entindex())
      if self.session:claim(pulse_id, key) then
        ApplyDamage({ victim = e, attacker = owner, damage = dmg, damage_type = dtype,
                      damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, ability = self:GetAbility() })
        hits = hits + 1
      end
    end
  end
  print(string.format("[RIFT][INFO][TA] pulse=%d source=%.1f coef=%.2f damage=%.1f type=%s hits=%d",
    pulse_id, source_damage or 0, coef, dmg, tostring(dtype), hits))
end

function modifier_rift_ta_crystal:OnDestroy()
  if not IsServer() then return end
  local p = self:GetParent()
  if p and not p:IsNull() and p:IsAlive() then
    if self.broken then p:ForceKill(false) else UTIL_Remove(p) end
  end
end
