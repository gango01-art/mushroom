-- Test fixtures: real data files with status forced to "implemented" (copies).
local F = {}
local function copy(t)
  if type(t) ~= "table" then return t end
  local r = {}
  for k, v in pairs(t) do r[k] = copy(v) end
  return r
end
F.copy = copy
-- mode: nil/"implemented" -> everything implemented; "planned" -> everything planned;
--       "shipped" -> data exactly as shipped.
function F.data(mode)
  package.loaded["rift.data.upgrades"] = nil
  package.loaded["rift.data.ultimate_directions"] = nil
  local ups = copy(require("rift.data.upgrades"))
  local dirs = copy(require("rift.data.ultimate_directions"))
  if mode ~= "shipped" then
    local st = (mode == "planned") and "planned" or "implemented"
    for _, u in ipairs(ups) do u.status = st end
    for _, d in ipairs(dirs) do d.status = st end
  end
  return ups, dirs
end
F.PA = "npc_dota_hero_phantom_assassin"
F.ULT = "phantom_assassin_coup_de_grace"
return F
