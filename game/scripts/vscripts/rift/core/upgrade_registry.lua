-- Registry and validator for regular upgrades and ultimate directions. Pure logic.

local Registry = {}
Registry.__index = Registry

Registry.RARITIES = { "common", "rare", "epic" }
local RARITY_SET = { common = true, rare = true, epic = true }
local DIRECTION_REQ = { any = true, physical = true, magical = true }
-- IDs from the abandoned legendary/evolution model must never come back.
local FORBIDDEN_PATTERNS = { "legendary", "evolution", "evo_" }

-- opts.handlers: set of effect handler names implemented in the engine (name -> true)
-- opts.loc: set of localization keys (key -> true), optional
function Registry.new(upgrades, directions, opts)
  local self = setmetatable({}, Registry)
  opts = opts or {}
  self.handlers = opts.handlers
  self.loc = opts.loc
  self.upgrades, self.by_id = {}, {}
  self.directions, self.dir_by_id, self.dir_by_hero = {}, {}, {}
  for _, u in ipairs(upgrades or {}) do
    table.insert(self.upgrades, u)
    self.by_id[u.id] = u
  end
  for _, d in ipairs(directions or {}) do
    table.insert(self.directions, d)
    self.dir_by_id[d.id] = d
    self.dir_by_hero[d.hero_id] = self.dir_by_hero[d.hero_id] or {}
    table.insert(self.dir_by_hero[d.hero_id], d)
  end
  return self
end

function Registry:get(id) return self.by_id[id] end
function Registry:direction(id) return self.dir_by_id[id] end

-- Returns { physical = def, magical = def } or nil.
function Registry:hero_directions(hero_id)
  local list = self.dir_by_hero[hero_id]
  if not list then return nil end
  local out = {}
  for _, d in ipairs(list) do out[d.direction] = d end
  return out
end

-- Hero is selectable only if both directions exist and are implemented.
function Registry:hero_enabled(hero_id)
  local d = self:hero_directions(hero_id)
  return d ~= nil and d.physical ~= nil and d.magical ~= nil
    and d.physical.status == "implemented" and d.magical.status == "implemented"
end

function Registry:ultimate_ability(hero_id)
  local list = self.dir_by_hero[hero_id]
  return list and list[1].ultimate_ability_id or nil
end

local function has_forbidden(id)
  local l = string.lower(id)
  for _, p in ipairs(FORBIDDEN_PATTERNS) do
    if string.find(l, p, 1, true) then return true end
  end
  return false
end

local function count_ranks(values, max_rank)
  for key, list in pairs(values or {}) do
    if type(list) == "table" and #list ~= max_rank then
      return key
    end
  end
  return nil
end

-- Returns list of error strings (empty = valid).
function Registry:validate()
  local errs = {}
  local function e(msg) table.insert(errs, msg) end
  local implemented = function(x) return x.status == "implemented" end

  for _, u in ipairs(self.upgrades) do
    local id = tostring(u.id)
    if has_forbidden(id) then e(id .. ": forbidden legacy id") end
    if u.type ~= "regular" then e(id .. ": type must be regular") end
    if not RARITY_SET[u.rarity] then e(id .. ": bad rarity " .. tostring(u.rarity)) end
    if not DIRECTION_REQ[u.required_direction] then e(id .. ": bad required_direction") end
    if type(u.max_rank) ~= "number" or u.max_rank < 1 then e(id .. ": bad max_rank") end
    local bad = count_ranks(u.values_by_rank, u.max_rank)
    if bad then e(id .. ": values_by_rank." .. bad .. " length ~= max_rank") end
    for _, p in ipairs(u.prerequisites or {}) do
      if not self.by_id[p] then e(id .. ": unknown prerequisite " .. p) end
      if p == u.id then e(id .. ": self prerequisite") end
    end
    if u.hero ~= "universal" and not self.dir_by_hero[u.hero] then
      e(id .. ": hero " .. tostring(u.hero) .. " has no ultimate directions")
    end
    if implemented(u) and self.handlers and not self.handlers[u.effect_handler] then
      e(id .. ": handler missing " .. tostring(u.effect_handler))
    end
    if implemented(u) and self.loc then
      if not self.loc[u.loc_name] then e(id .. ": missing loc " .. u.loc_name) end
      if not self.loc[u.loc_desc] then e(id .. ": missing loc " .. u.loc_desc) end
    end
  end

  for hero, list in pairs(self.dir_by_hero) do
    local phys, mag, fallback = 0, 0, 0
    local ult = list[1].ultimate_ability_id
    for _, d in ipairs(list) do
      if has_forbidden(d.id) then e(d.id .. ": forbidden legacy id") end
      if d.direction == "physical" then phys = phys + 1
      elseif d.direction == "magical" then mag = mag + 1
      else e(d.id .. ": bad direction " .. tostring(d.direction)) end
      if d.default_on_timeout then fallback = fallback + 1 end
      if d.ultimate_ability_id ~= ult then e(d.id .. ": ultimate_ability_id differs within hero") end
      if not d.learn_trigger_adapter then e(d.id .. ": missing learn_trigger_adapter") end
      for key, list2 in pairs(d.values_by_ultimate_rank or {}) do
        if type(list2) == "table" and #list2 ~= 3 then e(d.id .. ": values_by_ultimate_rank." .. key .. " needs 3 ranks") end
      end
      if implemented(d) and self.handlers then
        local h = d.active_handler or d.passive_handler
        if not h or not self.handlers[h] then e(d.id .. ": handler missing " .. tostring(h)) end
      end
      if implemented(d) and self.loc then
        if not self.loc[d.loc_name] then e(d.id .. ": missing loc " .. d.loc_name) end
        if not self.loc[d.loc_desc] then e(d.id .. ": missing loc " .. d.loc_desc) end
      end
    end
    if phys ~= 1 or mag ~= 1 or #list ~= 2 then e(hero .. ": needs exactly one physical and one magical direction") end
    if fallback ~= 1 then e(hero .. ": needs exactly one default_on_timeout direction") end
  end
  return errs
end

return Registry
