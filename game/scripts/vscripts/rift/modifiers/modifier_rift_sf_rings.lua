-- SF magical Requiem: permanent listener on the hero. After a SUCCESSFUL manual
-- Requiem cast (not interrupted, not the automatic death release):
--  * debuff-immune enemies in Requiem radius get one short fear (no damage);
--  * three delayed rings of Shadowraze eruptions around the fixed cast point.
-- Rules (timing, dedupe per ring/victim, immunity policy): core/heroes/sf_magical.
local B = require("rift.data.hero_balance").sf.requiem_magical
local Rings = require("rift.core.heroes.sf_magical")

modifier_rift_sf_rings = modifier_rift_sf_rings or ((type(class) == "function") and class({}) or {})
function modifier_rift_sf_rings:IsHidden() return true end
function modifier_rift_sf_rings:IsPurgable() return false end
function modifier_rift_sf_rings:RemoveOnDeath() return false end
function modifier_rift_sf_rings:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_rift_sf_rings:OnCreated()
  if not IsServer() then return end
  self.sessions = {}
  self:StartIntervalThink(0.05)
end

function modifier_rift_sf_rings:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_FULLY_CAST } end

local function protection(u)
  if u:IsInvulnerable() then return "invulnerable" end
  local immune = (u.IsDebuffImmune and u:IsDebuffImmune()) or u:IsMagicImmune()
  return immune and "debuff_immune" or "normal"
end

local function key(u)
  local gm = GameRules.RiftArena
  return (gm and gm.ids) and gm.ids:victim_key(u:entindex()) or tostring(u:entindex())
end

function modifier_rift_sf_rings:OnAbilityFullyCast(p)
  if not IsServer() then return end
  local me = self:GetParent()
  if p.unit ~= me or not p.ability or p.ability:GetAbilityName() ~= "nevermore_requiem" then return end
  if not me:IsAlive() or me:IsIllusion() then return end -- death release / illusions: no rings
  local rank = math.max(1, math.min(3, p.ability:GetLevel()))
  local gm = GameRules.RiftArena
  local cast_id = (gm and gm.ids) and gm.ids:next("requiem") or tostring(GameRules:GetGameTime())
  local o = me:GetAbsOrigin()
  local s = Rings.start(B, rank, cast_id, { x = o.x, y = o.y }, GameRules:GetGameTime())
  s.ability, s.z = p.ability, o.z
  -- Main Requiem: fear pierces debuff immunity (its damage does not - native rules keep that).
  local units = FindUnitsInRadius(me:GetTeamNumber(), o, nil, B.requiem_radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES +
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
  for _, u in ipairs(units) do
    local prot = protection(u)
    if prot == "debuff_immune" and not s.feared[key(u)] then
      s.feared[key(u)] = true
      require("rift.engine.mods").add(u, me, p.ability, "modifier_rift_sf_fear", { duration = B.immune_fear[rank] })
    end
  end
  table.insert(self.sessions, s)
end

function modifier_rift_sf_rings:OnIntervalThink()
  local gm = GameRules.RiftArena
  local finished = gm and gm.director and gm.director.state:is("FINISHED")
  local now = GameRules:GetGameTime()
  local me = self:GetParent()
  for i = #self.sessions, 1, -1 do
    local s = self.sessions[i]
    if finished then s:cancel() end
    for _, ev in ipairs(s:due(now)) do
      for _, pt in ipairs(ev.points) do
        local pos = Vector(pt.x, pt.y, s.z)
        pos = GetGroundPosition(pos, nil)
        local path = ev.kind == "telegraph" and B.telegraph_particle or B.eruption_particle
        local fx = ParticleManager:CreateParticle(path, PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleControl(fx, 0, pos)
        ParticleManager:ReleaseParticleIndex(fx)
        if ev.kind == "erupt" then
          local hits = FindUnitsInRadius(me:GetTeamNumber(), pos, nil, B.eruption_radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
          for _, u in ipairs(hits) do
            local r = s:resolve_hit(ev.ring, key(u), protection(u)) -- checked at hit time
            if r and r.damage > 0 then
              ApplyDamage({ victim = u, attacker = me, damage = r.damage, damage_type = DAMAGE_TYPE_MAGICAL,
                            ability = s.ability })
            end
            if r and r.fear > 0 then
              require("rift.engine.mods").add(u, me, s.ability, "modifier_rift_sf_fear", { duration = r.fear })
            end
          end
        end
      end
      if ev.kind == "erupt" then EmitSoundOnLocationWithCaster(Vector(s.center.x, s.center.y, s.z), "Hero_Nevermore.Shadowraze", me) end
    end
    if s:finished() then table.remove(self.sessions, i) end
  end
end
