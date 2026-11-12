-- Test fixtures: real data files with status forced to "implemented" (copies).
local F = {}
local function copy(t)
  if type(t) ~= "table" then return t end
  local r = {}
  for k, v in pairs(t) do r[k] = copy(v) end
  return r
end
F.copy = copy
function F.data(implemented)
  package.loaded["rift.data.upgrades"] = nil
  package.loaded["rift.data.ultimate_directions"] = nil
  local ups = copy(require("rift.data.upgrades"))
  local dirs = copy(require("rift.data.ultimate_directions"))
  if implemented ~= false then
    for _, u in ipairs(ups) do u.status = "implemented" end
    for _, d in ipairs(dirs) do d.status = "implemented" end
  end
  return ups, dirs
end
F.PA = "npc_dota_hero_phantom_assassin"
F.ULT = "phantom_assassin_coup_de_grace"
return F
