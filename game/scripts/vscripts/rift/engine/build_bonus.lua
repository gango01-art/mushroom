-- Regular build bonuses are server-owned. Learned branch talents and real item
-- bonuses are readable on both VMs, including native cooldown tooltips.
local M = {}

function M.get(unit, key)
  if not unit or unit:IsNull() or not unit.GetPlayerOwnerID then return 0 end
  local progression=require("rift.engine.progression").get(unit,key)
  if not IsServer()then return progression end
  local gm = GameRules.RiftArena
  if not gm or not gm.upgrades then return progression end
  local pid = unit:GetPlayerOwnerID()
  if pid == nil or pid < 0 then return progression end
  return gm.upgrades:Bonus(pid, key)+progression
end

return M
