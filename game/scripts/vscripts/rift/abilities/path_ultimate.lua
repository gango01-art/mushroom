-- Class-per-KV-name, shared implementation. Loaded on server AND client.
local Expansion = require("rift.data.expansion")
local Math = require("rift.core.path_math")
for name, profile in pairs(Expansion.abilities) do
  local d = profile -- capture this iteration for Lua 5.1 closures
  local A = _G[name] or ((type(class) == "function") and class({}) or {})
  _G[name] = A
  function A:GetCooldown(level) return Math.rank(d.cooldown, level + 1) end
  function A:GetManaCost(level) return Math.rank(d.mana, level + 1) end
  function A:GetCastRange() return d.range end
  function A:GetAOERadius() return d.radius end
  function A:GetAbilityTextureName() return d.icon end
  function A:OnSpellStart()
    if IsServer() then require("rift.engine.path_combat").cast(self, d) end
  end
end
