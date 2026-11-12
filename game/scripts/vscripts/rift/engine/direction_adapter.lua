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
    swap.fresh and { level = 0, cooldown_remaining = 0 }
      or { level = from:GetLevel(), cooldown_remaining = from:GetCooldownTimeRemaining() },
    { max_level = to:GetMaxLevel(), full_cooldown_at = function(l) return to:GetCooldown(l - 1) end })
  hero:SwapAbilities(swap.from, swap.to, false, true)
  -- disable_from: the hidden native must not keep working (e.g. SF death Requiem in physical direction).
  if swap.disable_from then from:SetLevel(0) end
  to:SetLevel(plan.level)
  to:SetActivated(true)
  if plan.cooldown > 0 then to:StartCooldown(plan.cooldown) end
  Log.info("DIRECTION", string.format("swap %s -> %s level=%d cd=%.1f", swap.from, swap.to, plan.level, plan.cooldown))
  return true
end

-- Visible ability layout (first slots only; talents/hidden ignored) for diagnostics
-- and for restoring abilities hidden as a side effect of a swap (OP-013: Refraction
-- disappeared from the bar after the TA physical swaps).
local function layout(hero)
  local out, visible = {}, {}
  for i = 0, math.min(hero:GetAbilityCount() - 1, 9) do
    local a = hero:GetAbilityByIndex(i)
    if a and not a:IsNull() then
      local name = a:GetAbilityName()
      if name:find("special_bonus_", 1, true) ~= 1 then
        table.insert(out, string.format("%d:%s%s", i, name, a:IsHidden() and "(h)" or ""))
        if not a:IsHidden() then visible[name] = a:GetLevel() end
      end
    end
  end
  return table.concat(out, " "), visible
end

-- Put abilities into slots (hotkeys follow slots: 0 Q, 1 W, 2 E, 3 D, 4 F, 5 R).
-- order entries: "name" -> slot = position-1, or { name = "...", slot = n }.
-- Visibility is restored explicitly afterwards: SwapAbilities' enable flags hid
-- abilities that passed through high slots (OP-018: Meld/Psi Blades became hidden).
local function apply_order(hero, order)
  if not order or #order == 0 then return end
  local hidden0 = {}
  for i = 0, hero:GetAbilityCount() - 1 do
    local a = hero:GetAbilityByIndex(i)
    if a and not a:IsNull() then hidden0[a:GetAbilityName()] = a:IsHidden() end
  end
  local wanted = {}
  for i, e in ipairs(order) do
    local name = type(e) == "table" and e.name or e
    local slot = type(e) == "table" and e.slot or (i - 1)
    wanted[name] = true
    local a = hero:FindAbilityByName(name)
    if a and a:GetAbilityIndex() ~= slot then
      local other = hero:GetAbilityByIndex(slot)
      if other and not other:IsNull() then
        hero:SwapAbilities(name, other:GetAbilityName(), true, not hidden0[other:GetAbilityName()])
      end
    end
  end
  for name, was_hidden in pairs(hidden0) do
    local a = hero:FindAbilityByName(name)
    if a then a:SetHidden(not wanted[name] and was_hidden) end
  end
end

-- Familiar layout guard (owner request): the visible ultimate always sits in slot 5,
-- which is the R hotkey. Applies to every hero/direction, even without an order list.
local ULT_SLOT = 5
local function keep_ultimate_on_r(hero)
  for i = 0, math.min(hero:GetAbilityCount() - 1, 9) do
    local a = hero:GetAbilityByIndex(i)
    if a and not a:IsNull() and not a:IsHidden() and a:GetAbilityType() == ABILITY_TYPE_ULTIMATE
       and a:GetAbilityName():find("special_bonus_", 1, true) ~= 1 then
      if i ~= ULT_SLOT then
        apply_order(hero, { { name = a:GetAbilityName(), slot = ULT_SLOT } })
        Log.info("DIRECTION", "ultimate moved to R slot: " .. a:GetAbilityName())
      end
      return
    end
  end
end

-- Base kit on first spawn (data/hero_kits.lua).
function Adapter:ApplyKit(hero)
  local kit = require("rift.data.hero_kits")[hero:GetUnitName()]
  if not kit then return end
  for _, name in ipairs(kit.add or {}) do
    if not hero:FindAbilityByName(name) then
      local a = hero:AddAbility(name)
      if not a then Log.error("DIRECTION", "kit ability missing in this client: " .. name) end
    end
  end
  apply_order(hero, kit.order)
  keep_ultimate_on_r(hero)
  Log.info("DIRECTION", "kit applied for " .. hero:GetUnitName() .. ": " .. (layout(hero)))
end

function Adapter:Apply(pid, def)
  self.locked[pid] = nil
  self.applied[pid] = def.id
  local hero = hero_of(pid)
  if not hero then return end
  local before, was_visible = layout(hero)
  Log.info("DIRECTION", "layout before: " .. before)
  local swapped = {}
  for _, swap in ipairs(def.swaps or {}) do
    swapped[swap.from] = true
    self:_swap(hero, swap, def.transfer_policy)
  end
  for _, name in ipairs(def.hide or {}) do
    local a = hero:FindAbilityByName(name)
    if a then a:SetHidden(true); swapped[name] = true end
  end
  -- Useless natives are removed outright (a hidden ability can still leave an empty slot on the bar).
  for _, name in ipairs(def.remove or {}) do
    if hero:FindAbilityByName(name) then hero:RemoveAbility(name) end
    swapped[name] = true
  end
  apply_order(hero, def.order)
  keep_ultimate_on_r(hero)
  -- Self-heal: anything visible before that we did not replace or hide must stay visible.
  for name, level in pairs(was_visible) do
    local a = hero:FindAbilityByName(name)
    if not swapped[name] then
      if not a then
        -- Removed/overwritten by the swap: put it back with its level (points are not refunded twice).
        a = hero:AddAbility(name)
        if a then a:SetLevel(level) end
        Log.error("DIRECTION", "swap removed an unrelated ability, re-added: " .. name .. " level=" .. level)
      elseif a:IsHidden() then
        a:SetHidden(false)
        Log.error("DIRECTION", "swap hid an unrelated ability, restored: " .. name)
      end
    end
  end
  Log.info("DIRECTION", "layout after: " .. (layout(hero)))
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
