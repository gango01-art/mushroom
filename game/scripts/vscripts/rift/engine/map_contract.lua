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
  local c = { spawns = {}, relics = {}, bases={}, ward_spots={}, river_camps={}, roshan_pockets={}, center = nil, fallback = false }
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
  for _,team in ipairs(require("rift.core.config").sanctuary.teams)do
    local base=find("rift_base_"..team)
    local tower=find("rift_base_tower_"..team)
    if base and tower then base.team,base.tower=team,tower;base.spawn=find("rift_team_start_"..team);c.bases[#c.bases+1]=base
    else missing[#missing+1]="rift_base/tower_"..team end
  end

  for i=1,4 do
    local name=name2("rift_ward_",i);local p=find(name)
    if p then c.ward_spots[#c.ward_spots+1]=p else missing[#missing+1]=name end
  end
  for i=1,4 do
    local name=name2("rift_river_camp_",i);local p=find(name)
    if p then c.river_camps[#c.river_camps+1]=p else missing[#missing+1]=name end
  end
  for i=1,2 do
    local name=name2("rift_roshan_",i);local p=find(name)
    if p then c.roshan_pockets[#c.roshan_pockets+1]=p else missing[#missing+1]=name end
  end
  if #missing == 0 then
    for _, err in ipairs(require("rift.core.arena").validate(c)) do missing[#missing+1] = err end
  end
  if #missing > 0 then
    for _, n in ipairs(missing) do
      if dev then Log.warn("MAP", "missing entity " .. n)
      else Log.error("MAP", "missing entity " .. n) end
    end
    -- Never mix valid starts with an empty relic list or invalid bounds.
    MapContract.apply_fallback(c)
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
  c.spawns, c.relics, c.bases = {}, {}, {}
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
