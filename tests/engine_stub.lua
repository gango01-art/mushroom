-- Minimal fake of the Dota server API for smoke-testing engine modules with lua5.1.
-- It checks OUR logic flow (sessions, cleanup, numbers), not Valve's API: a method the
-- fake does not know raises an error, so every engine call used by a tested module is
-- listed here explicitly. Real behaviour is still verified only in Dota.
local S = {}

local V = {}
V.__index = V
local function vec(x, y, z) return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, V) end
V.__add = function(a, b) return vec(a.x + b.x, a.y + b.y, a.z + b.z) end
V.__sub = function(a, b) return vec(a.x - b.x, a.y - b.y, a.z - b.z) end
V.__mul = function(a, b) if type(a) == "number" then a, b = b, a end return vec(a.x * b, a.y * b, a.z * b) end
V.__div = function(a, b) return vec(a.x / b, a.y / b, a.z / b) end
function V:Length2D() return math.sqrt(self.x * self.x + self.y * self.y) end
function V:Normalized() local l = self:Length2D(); return l > 0 and vec(self.x / l, self.y / l, 0) or vec(1, 0, 0) end

local Unit = {}
Unit.__index = function(u, k)
  if Unit[k] then return Unit[k] end
  local set = k:match("^Set(.+)$")
  if set then return function(self, v) self.props[set] = v end end
  local get = k:match("^Get(.+)$")
  if get then
    return function(self)
      if self.props[get] == nil then error("fake unit: no value for Get" .. get .. " on " .. self.name, 2) end
      return self.props[get]
    end
  end
  error("fake unit: unknown method " .. tostring(k) .. " on " .. u.name, 2)
end
function Unit:IsNull() return self.removed end
function Unit:IsAlive() return not self.removed and not self.dead end
function Unit:IsRealHero() return self.hero end
function Unit:IsHero() return self.hero end
function Unit:IsIllusion() return false end
function Unit:IsInvulnerable() return self.mods.modifier_rift_lc_throne ~= nil end
function Unit:IsMagicImmune() return self.immune or false end
function Unit:PassivesDisabled() return self.broken or false end
function Unit:GetUnitName() return self.name end
function Unit:GetAbsOrigin() return self.pos end
function Unit:SetAbsOrigin(p) self.pos = p end
function Unit:GetForwardVector() return vec(1, 0, 0) end
function Unit:SetForwardVector() end
function Unit:GetTeamNumber() return self.team end
function Unit:GetPlayerOwnerID() return self.pid end
function Unit:GetAverageTrueAttackDamage() return self.props.Damage end
function Unit:GetPhysicalArmorValue() return self.props.Armor end
function Unit:GetAttacksPerSecond() return self.props.APS end
function Unit:Stop() end
function Unit:SetIdleAcquire() end
function Unit:SetRenderColor() end
function Unit:MoveToTargetToAttack(t) self.attack_target = t end
function Unit:GetAttackTarget() return self.attack_target or nil end
function Unit:ForceKill() self.dead = true end
function Unit:HasModifier(n) return self.mods[n] ~= nil end
function Unit:FindModifierByName(n) return self.mods[n] end
function Unit:RemoveModifierByName(n) self.mods[n] = nil end
function Unit:AddNewModifier(_, _, name, kv)
  local m = { name = name, kv = kv, stacks = 0 }
  function m:GetStackCount() return self.stacks end
  function m:SetStackCount(n) self.stacks = n end
  self.mods[name] = m
  return m
end
function Unit:FindAbilityByName(n) return self.abilities[n] end
function Unit:SetContextThink(name, fn, delay) S.thinks[tostring(self) .. name] = { fn = fn, at = S.now + (delay or 0) } end
function Unit:entindex() return self.index end
function Unit:IsBuilding() return false end
function Unit:IsOther() return false end
function Unit:IsDebuffImmune() return self.immune or false end
function Unit:TriggerSpellAbsorb() return self.linkens or false end
function Unit:GetStatusResistance() return 0 end

local seq = 0
function S.unit(name, o)
  seq = seq + 1
  o = o or {}
  S.by_index = S.by_index or {}
  local u = { name = name, index = seq, props = o.props or {}, mods = {}, abilities = o.abilities or {},
              pos = o.pos or vec(0, 0, 0), team = o.team or 2, pid = o.pid or -1, hero = o.hero or false,
              removed = false, dead = false, broken = false, attack_target = false,
              immune = false, linkens = false }
  S.by_index[u.index] = u
  return setmetatable(u, Unit)
end

function S.ability(level)
  local a = { level = level or 1, cd = 0 }
  function a:IsNull() return false end
  function a:GetLevel() return self.level end
  function a:GetCooldownTimeRemaining() return math.max(0, self.cd - S.now) end
  function a:EndCooldown() self.cd = 0 end
  function a:StartCooldown(t) self.cd = S.now + t end
  return a
end

-- Advance fake time, running due thinks (each think returns its next delay or nil).
function S.advance(dt, step)
  step = step or 0.1
  local stop = S.now + dt
  while S.now < stop - 1e-9 do
    S.now = S.now + step
    for key, t in pairs(S.thinks) do
      if t.at <= S.now + 1e-9 then
        local nxt = t.fn()
        if nxt then t.at = S.now + nxt else S.thinks[key] = nil end
      end
    end
  end
end

function S.install()
  S.now, S.thinks, S.damage, S.created, S.projectiles, S.heroes = 0, {}, {}, {}, {}, {}
  local mode = S.unit("gamemode")
  _G.IsServer = function() return true end
  _G.IsInToolsMode = function() return false end
  _G.Vector = vec
  _G.GameRules = { GetGameTime = function() return S.now end, GetGameModeEntity = function() return mode end }
  _G.CreateUnitByName = function(name, pos, _, _, _, team)
    local u = S.unit(name, { pos = pos, team = team })
    table.insert(S.created, u)
    return u
  end
  _G.UTIL_Remove = function(u) u.removed = true end
  _G.ApplyDamage = function(t)
    table.insert(S.damage, t)
    return t.damage
  end
  _G.EmitSoundOn = function() end
  _G.EmitSoundOnLocationWithCaster = function() end
  _G.SendOverheadEventMessage = function() end
  _G.EntIndexToHScript = function(i) return S.by_index[i] end
  _G.GetGroundPosition = function(p) return p end
  _G.class = function(t) return t or {} end
  _G.ParticleManager = { CreateParticle = function() return 1 end, SetParticleControl = function() end,
                         ReleaseParticleIndex = function() end, DestroyParticle = function() end }
  _G.FindUnitsInRadius = function(team, pos, _, radius)
    local out = {}
    for _, h in ipairs(S.heroes) do
      if h.team ~= team and h:IsAlive() and (h.pos - pos):Length2D() <= radius then table.insert(out, h) end
    end
    return out
  end
  _G.ProjectileManager = { CreateTrackingProjectile = function(_, p) table.insert(S.projectiles, p) end }
  _G.PlayerResource = {
    GetConnectionState = function() return 2 end,
    GetSelectedHeroEntity = function(_, pid) for _, h in ipairs(S.heroes) do if h.pid == pid then return h end end end,
  }
  for _, c in ipairs({ "DOTA_CONNECTION_STATE_CONNECTED" }) do _G[c] = 2 end
  for _, c in ipairs({ "DAMAGE_TYPE_PURE", "DAMAGE_TYPE_MAGICAL", "DAMAGE_TYPE_PHYSICAL", "DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION",
    "DOTA_DAMAGE_FLAG_REFLECTION", "DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS", "DOTA_UNIT_TARGET_TEAM_ENEMY",
    "DOTA_UNIT_TARGET_HERO", "DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE", "DOTA_UNIT_TARGET_FLAG_NO_INVIS",
    "DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS", "DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES", "FIND_CLOSEST",
    "DOTA_PROJECTILE_ATTACHMENT_HITLOCATION", "DOTA_PROJECTILE_ATTACHMENT_ATTACK_1", "DOTA_UNIT_TARGET_BASIC",
    "DOTA_UNIT_TARGET_FLAG_INVULNERABLE", "FIND_ANY_ORDER", "OVERHEAD_ALERT_CRITICAL", "PATTACH_WORLDORIGIN",
    "PATTACH_ABSORIGIN_FOLLOW", "MODIFIER_ATTRIBUTE_PERMANENT" }) do _G[c] = 1 end
  for name in pairs(package.loaded) do
    if name:find("^rift%.engine%.") then package.loaded[name] = nil end
  end
  return S
end

-- Instance of a Lua ability class (file under rift/abilities) bound to a caster.
function S.lua_ability(name, caster, level)
  package.loaded["rift.abilities." .. name] = nil
  _G[name] = nil
  require("rift.abilities." .. name)
  local a = S.ability(level)
  a.caster = caster
  function a:GetCaster() return self.caster end
  function a:GetCursorTarget() return self.cursor end
  function a:GetAbilityName() return name end
  function a:GetSpecialValueFor() return 0 end
  caster.abilities[name] = a
  return setmetatable(a, { __index = _G[name] })
end

-- Instance of a Lua modifier class (file under rift/modifiers) on a parent unit.
function S.lua_modifier(name, parent, ability)
  package.loaded["rift.modifiers." .. name] = nil
  _G[name] = nil
  require("rift.modifiers." .. name)
  local m = { stacks = 0, destroyed = false }
  function m:GetParent() return parent end
  function m:GetAbility() return ability end
  function m:GetStackCount() return self.stacks end
  function m:SetStackCount(n) self.stacks = n end
  function m:StartIntervalThink() end
  function m:Destroy() self.destroyed = true end
  setmetatable(m, { __index = _G[name] })
  m:OnCreated({})
  return m
end

function S.hero(name, pid, team, pos, props)
  local h = S.unit(name, { pid = pid, team = team, pos = pos, hero = true, props = props })
  table.insert(S.heroes, h)
  return h
end

return S
