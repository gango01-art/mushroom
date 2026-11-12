-- Server-side read of an ability bonus from the owner's upgrade build. Returns 0 on the
-- client (the build is server state), for non-player units and before the mode starts.
local M = {}

function M.get(unit, key)
  if not IsServer() or not unit or unit:IsNull() or not unit.GetPlayerOwnerID then return 0 end
  local gm = GameRules.RiftArena
  if not gm or not gm.upgrades then return 0 end
  local pid = unit:GetPlayerOwnerID()
  if pid == nil or pid < 0 then return 0 end
  return gm.upgrades:Bonus(pid, key)
end

return M
