-- Map contract: named entities the map must provide (see docs/MAP_CONTRACT.md).
-- On maps without them (e.g. the dev map "dota") a clearly logged DEV FALLBACK is used.

local Log = require("rift.engine.log")

local MapContract = {}

MapContract.SPAWN_COUNT = 12
MapContract.RELIC_COUNT = 4

local function name2(prefix, i) return string.format("%s%02d", prefix, i) end

local function find(name)
  local e = Entities:FindByName(nil, name)
  if e then
    local p = e:GetAbsOrigin()
    return { name = name, x = p.x, y = p.y, z = p.z }
  end
  return nil
end

-- Returns contract table and list of missing names.
function MapContract.load(dev)
  local c = { spawns = {}, relics = {}, center = nil, fallback = false }
  local missing = {}
  for i = 1, MapContract.SPAWN_COUNT do
    local n = name2("rift_spawn_", i)
    local p = find(n)
    if p then table.insert(c.spawns, p) else table.insert(missing, n) end
  end
  for i = 1, MapContract.RELIC_COUNT do
    local n = name2("rift_relic_", i)
    local p = find(n)
    if p then table.insert(c.relics, p) else table.insert(missing, n) end
  end
  c.center = find("rift_center")
  if not c.center then table.insert(missing, "rift_center") end
  c.bounds_min = find("rift_bounds_min")
  if not c.bounds_min then table.insert(missing, "rift_bounds_min") end
  c.bounds_max = find("rift_bounds_max")
  if not c.bounds_max then table.insert(missing, "rift_bounds_max") end

  if #missing > 0 then
    for _, n in ipairs(missing) do
      if dev then Log.warn("MAP", "missing entity " .. n)
      else Log.error("MAP", "missing entity " .. n) end
    end
    if #c.spawns < MapContract.SPAWN_COUNT then
      MapContract.apply_fallback(c)
    end
  else
    Log.info("MAP", "contract OK: 12 spawns, 4 relic points, center, bounds")
  end
  c.missing = missing
  return c
end

-- DEV FALLBACK: ring of points around world origin. Valid only for logic testing.
function MapContract.apply_fallback(c)
  Log.warn("MAP", "DEV FALLBACK spawn ring in use - not a real arena map")
  c.fallback = true
  c.spawns, c.relics = {}, {}
  local R = 2400
  for i = 1, MapContract.SPAWN_COUNT do
    local a = (i - 1) / MapContract.SPAWN_COUNT * 2 * math.pi
    table.insert(c.spawns, { name = name2("fallback_spawn_", i), x = R * math.cos(a), y = R * math.sin(a), z = 0 })
  end
  for i = 1, MapContract.RELIC_COUNT do
    local a = (i - 1) / MapContract.RELIC_COUNT * 2 * math.pi + math.pi / 4
    table.insert(c.relics, { name = name2("fallback_relic_", i), x = 900 * math.cos(a), y = 900 * math.sin(a), z = 0 })
  end
  c.center = c.center or { name = "fallback_center", x = 0, y = 0, z = 0 }
end

return MapContract
