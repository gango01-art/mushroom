-- DEV ONLY. Logs attack/damage event fields of its parent so engine semantics
-- (crit in OnAttackLanded damage, attack records, Psi Blades spill damage) can be
-- verified in the installed client before dependent code is written.
modifier_rift_attack_probe = class({})

function modifier_rift_attack_probe:IsHidden() return false end
function modifier_rift_attack_probe:IsPurgable() return false end
function modifier_rift_attack_probe:RemoveOnDeath() return false end
function modifier_rift_attack_probe:GetTexture() return "templar_assassin_psi_blades" end

function modifier_rift_attack_probe:DeclareFunctions()
  return { MODIFIER_EVENT_ON_ATTACK_START, MODIFIER_EVENT_ON_ATTACK, MODIFIER_EVENT_ON_ATTACK_LANDED,
           MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY, MODIFIER_EVENT_ON_TAKEDAMAGE }
end

local function name(u) return (u and not u:IsNull() and u.GetUnitName) and (u:GetUnitName() .. "#" .. u:entindex()) or "nil" end

local function log(tag, p)
  print(string.format("[RIFT][PROBE] %s t=%.3f attacker=%s target=%s unit=%s record=%s damage=%s original=%s type=%s cat=%s flags=%s inflictor=%s",
    tag, GameRules:GetGameTime(), name(p.attacker), name(p.target), name(p.unit), tostring(p.record),
    tostring(p.damage), tostring(p.original_damage), tostring(p.damage_type), tostring(p.damage_category),
    tostring(p.damage_flags), p.inflictor and p.inflictor:GetAbilityName() or "nil"))
end

function modifier_rift_attack_probe:OnAttackStart(p) if IsServer() and p.attacker == self:GetParent() then log("attack_start", p) end end
function modifier_rift_attack_probe:OnAttack(p) if IsServer() and p.attacker == self:GetParent() then log("attack", p) end end
function modifier_rift_attack_probe:OnAttackLanded(p) if IsServer() and p.attacker == self:GetParent() then log("attack_landed", p) end end
function modifier_rift_attack_probe:OnAttackRecordDestroy(p) if IsServer() and p.attacker == self:GetParent() then log("record_destroy", p) end end
function modifier_rift_attack_probe:OnTakeDamage(p) if IsServer() and p.attacker == self:GetParent() then log("take_damage", p) end end
