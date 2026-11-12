-- Applies ultimate directions to the hero entity.
--  * Lock: while the direction offer is pending, the native ultimate is deactivated
--    (no free use of either version). Passive natives (e.g. PA crit) keep their
--    baseline effect; a direction's NEW effects only start after the choice.
--  * Apply: per direction data `swaps = { { from = native, to = custom } }` the
--    custom ability takes the slot with the native's level and remaining cooldown
--    (rift/core/ability_transfer). `modifiers = { names }` are added once.
--  * Ensure: idempotent restore after respawn / reconnect.
-- Per-player state lives on the server (offers.player(pid).direction_id), not on
-- the hero handle, so it survives death and reconnect.

local Transfer = require("rift.core.ability_transfer")
local Mods = require("rift.engine.mods")
local Log = require("rift.engine.log")

local Adapter = {}
Adapter.__index = Adapter

function Adapter.new(bridge)
  return setmetatable({ bridge = bridge, locked = {}, applied = {} }, Adapter)
end

local function hero_of(pid)
  local h = PlayerResource:GetSelectedHeroEntity(pid)
  if h and not h:IsNull() then return h end
  return nil
end

function Adapter:_ultimate(pid, hero)
  local p = self.bridge.offers:player(pid)
  local name = p and self.bridge.registry:ultimate_ability(p.hero)
  return name and hero:FindAbilityByName(name) or nil, name
end

function Adapter:Lock(pid)
  self.locked[pid] = true
  local hero = hero_of(pid)
  local ult = hero and self:_ultimate(pid, hero)
  if ult then ult:SetActivated(false) end
end

function Adapter:_swap(hero, swap, policy)
  local from = hero:FindAbilityByName(swap.from)
  if not from then
    Log.error("DIRECTION", "native ability missing: " .. tostring(swap.from))
    return false
  end
  local to = hero:FindAbilityByName(swap.to) or hero:AddAbility(swap.to)
  if not to then
    Log.error("DIRECTION", "custom ability missing: " .. tostring(swap.to))
    return false
  end
  local plan = Transfer.plan(policy or "keep_rank_keep_cooldown",
    { level = from:GetLevel(), cooldown_remaining = from:GetCooldownTimeRemaining() },
    { max_level = to:GetMaxLevel(), full_cooldown_at = function(l) return to:GetCooldown(l - 1) end })
  hero:SwapAbilities(swap.from, swap.to, false, true)
  to:SetLevel(plan.level)
  to:SetActivated(true)
  if plan.cooldown > 0 then to:StartCooldown(plan.cooldown) end
  Log.info("DIRECTION", string.format("swap %s -> %s level=%d cd=%.1f", swap.from, swap.to, plan.level, plan.cooldown))
  return true
end

function Adapter:Apply(pid, def)
  self.locked[pid] = nil
  self.applied[pid] = def.id
  local hero = hero_of(pid)
  if not hero then return end
  for _, swap in ipairs(def.swaps or {}) do self:_swap(hero, swap, def.transfer_policy) end
  local ult = self:_ultimate(pid, hero)
  if ult then ult:SetActivated(true) end
  self:_ensure_modifiers(hero, def)
end

function Adapter:_ensure_modifiers(hero, def)
  for _, m in ipairs(def.modifiers or {}) do
    if not hero:HasModifier(m) then Mods.add(hero, hero, nil, m, {}) end
  end
end

-- Called on every respawn / reconnect of the main hero.
function Adapter:Ensure(pid, hero)
  if self.locked[pid] then
    local ult = self:_ultimate(pid, hero)
    if ult then ult:SetActivated(false) end
  end
  local id = self.applied[pid]
  if id then
    local def = self.bridge.registry:direction(id)
    if def then self:_ensure_modifiers(hero, def) end
  end
end

return Adapter
