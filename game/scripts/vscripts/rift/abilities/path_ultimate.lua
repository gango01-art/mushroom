-- Class-per-KV-name, shared implementation. Loaded on server AND client.
local Expansion = require("rift.data.expansion")
local Math = require("rift.core.path_math")
for name, profile in pairs(Expansion.abilities) do
  local d = profile -- capture this iteration for Lua 5.1 closures
  local A = _G[name] or ((type(class) == "function") and class({}) or {})
  _G[name] = A
  function A:GetCooldown(level) return require("rift.engine.progression").cooldown(self:GetCaster(),self,Math.rank(d.cooldown, require("rift.engine.ability_level")(self,level))) end
  function A:GetManaCost(level) return Math.rank(d.mana, require("rift.engine.ability_level")(self,level)) end
  function A:GetCastRange() return require("rift.engine.progression").profile(self:GetCaster(),self,d).range end
  function A:GetAOERadius() return require("rift.engine.area").radius(self:GetCaster(), require("rift.engine.progression").radius(self:GetCaster(),self,d.radius)) end
  function A:OnProjectileHit_ExtraData(target, _, data)
    if IsServer() then return require("rift.engine.path_combat").projectile_hit(target, data) end
  end
  function A:GetAbilityTextureName() return d.icon end
  function A:GetIntrinsicModifierName()
    if d.id == "rift_juggernaut_physical" then return "modifier_rift_attack_cooldowns" end
  end
  function A:OnSpellStart()
    if IsServer() then require("rift.engine.path_combat").cast(self, d) end
  end
end
