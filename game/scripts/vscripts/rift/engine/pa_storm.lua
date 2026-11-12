-- Shared server state for PA magical "Storm Daggers": one seeded cast-context store
-- per match (core/pa_storm_daggers), so the 20% roll is server-side and reproducible.
local Storm = require("rift.core.pa_storm_daggers")

local M = {}

function M.store()
  if not M._store then
    local gm = GameRules.RiftArena
    M._store = Storm.new(gm and gm.upgrades and gm.upgrades.seed or 1)
  end
  return M._store
end

return M
