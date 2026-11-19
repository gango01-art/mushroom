-- A backup guard for blinks, forced movement and terrain escape. Does not
-- replace terrain collision/nav, and does not constrain the standard dev map.
local Geometry = require("rift.core.arena")
local A = {}
function A.tick(gm)
  local map = gm.map
  if not map or map.fallback or not map.bounds_min or not map.bounds_max then return end
  for pid in pairs(gm.players) do
    local h = PlayerResource:GetSelectedHeroEntity(pid)
    if h and not h:IsNull() and h:IsAlive() then
      local pos = h:GetAbsOrigin()
      if not Geometry.inside(pos,map.bounds_min,map.bounds_max) then
        local safe = Geometry.clamp(pos,map.bounds_min,map.bounds_max,160)
        FindClearSpaceForUnit(h,GetGroundPosition(Vector(safe.x,safe.y,safe.z),h),true)
        h:Stop()
      end
    end
  end
end
return A
