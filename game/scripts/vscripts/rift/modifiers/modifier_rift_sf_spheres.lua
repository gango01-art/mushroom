-- SF physical Requiem state. Stack count = available red spheres (0-4) for the HUD.
-- Attack released at a valid enemy -> spends at most one sphere and remembers the
-- attack record; when THAT record lands -> one separate physical hit of 60% attack
-- damage (no crit multiplier, no own crit roll). Miss/disjoint: sphere is not
-- returned. Shadowraze hit while active -> one physical bonus per (cast, victim).
-- Bonus damage uses this ability as inflictor, so it never re-triggers razes/spheres.
local B = require("rift.data.hero_balance").sf.requiem_physical
local Spheres = require("rift.core.heroes.sf_physical")

modifier_rift_sf_spheres = modifier_rift_sf_spheres or ((type(class) == "function") and class({}) or {})
function modifier_rift_sf_spheres:IsHidden() return false end
function modifier_rift_sf_spheres:IsPurgable() return false end
function modifier_rift_sf_spheres:RemoveOnDeath() return true end
function modifier_rift_sf_spheres:GetTexture() return "nevermore_requiem" end

local function attack_damage(unit)
  -- Average attack damage without crit (base + bonus); verified behaviour pending OP-016.
  return unit:GetAverageTrueAttackDamage(nil)
end

function modifier_rift_sf_spheres:OnCreated()
  if not IsServer() then return end
  local p = self:GetParent()
  if p:IsIllusion() then self:Destroy(); return end -- illusions get no own sphere pool
  local a = self:GetAbility()
  self.session = Spheres.start(B, math.max(1, a and a:GetLevel() or 1), GameRules:GetGameTime())
  self.records = {}
  self.raze_casts = {}
  self:SetStackCount(self.session.charges)
  self.fx = {}
  if B.wings_particle ~= "" then
    table.insert(self.fx, ParticleManager:CreateParticle(B.wings_particle, PATTACH_ABSORIGIN_FOLLOW, p))
  end
  self:StartIntervalThink(0.1)
end

function modifier_rift_sf_spheres:OnIntervalThink()
  self.session:update(GameRules:GetGameTime())
  self:SetStackCount(self.session.charges)
end

function modifier_rift_sf_spheres:DeclareFunctions()
  return { MODIFIER_EVENT_ON_ATTACK, MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
           MODIFIER_EVENT_ON_ABILITY_EXECUTED, MODIFIER_EVENT_ON_TAKEDAMAGE }
end

local function valid_enemy(p, t)
  return t and not t:IsNull() and t:GetTeamNumber() ~= p:GetTeamNumber() and not t:IsBuilding()
     and not t:IsOther() and t:IsAlive()
end

function modifier_rift_sf_spheres:OnAttack(params)
  if not IsServer() or params.attacker ~= self:GetParent() then return end
  if self.session:consume(GameRules:GetGameTime(), valid_enemy(params.attacker, params.target)) then
    self.records[params.record] = true
    self:SetStackCount(self.session.charges)
  end
end

function modifier_rift_sf_spheres:OnAttackLanded(params)
  if not IsServer() or params.attacker ~= self:GetParent() or not self.records[params.record] then return end
  self.records[params.record] = nil
  local p = self:GetParent()
  ApplyDamage({ victim = params.target, attacker = p, damage = self.session:sphere_damage(attack_damage(p)),
                damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
                ability = self:GetAbility() })
end

function modifier_rift_sf_spheres:OnAttackRecordDestroy(params)
  if IsServer() and params.attacker == self:GetParent() then self.records[params.record] = nil end
end

local function is_raze(ability)
  return ability and not ability:IsNull() and ability.GetAbilityName
     and ability:GetAbilityName():find("nevermore_shadowraze", 1, true) == 1
end

function modifier_rift_sf_spheres:OnAbilityExecuted(params)
  if IsServer() and params.unit == self:GetParent() and is_raze(params.ability) then
    local n = params.ability:GetAbilityName()
    self.raze_casts[n] = (self.raze_casts[n] or 0) + 1
  end
end

function modifier_rift_sf_spheres:OnTakeDamage(params)
  if not IsServer() or params.attacker ~= self:GetParent() or not is_raze(params.inflictor) then return end
  local victim = params.unit
  if not valid_enemy(params.attacker, victim) then return end
  local n = params.inflictor:GetAbilityName()
  local gm = GameRules.RiftArena
  local key = (gm and gm.ids) and gm.ids:victim_key(victim:entindex()) or tostring(victim:entindex())
  local frac = self.session:claim_raze(GameRules:GetGameTime(), n .. "#" .. (self.raze_casts[n] or 0), key)
  if frac then
    local p = self:GetParent()
    ApplyDamage({ victim = victim, attacker = p, damage = attack_damage(p) * frac, damage_type = DAMAGE_TYPE_PHYSICAL,
                  damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, ability = self:GetAbility() })
  end
end

function modifier_rift_sf_spheres:OnDestroy()
  if not IsServer() then return end
  for _, fx in ipairs(self.fx or {}) do
    ParticleManager:DestroyParticle(fx, false)
    ParticleManager:ReleaseParticleIndex(fx)
  end
end
