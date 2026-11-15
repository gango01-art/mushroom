-- Engine-free geometry and damage. A cast snapshots attack/attributes once.
local M = {}
function M.rank(v, rank)
  if type(v) ~= "table" then return v or 0 end
  return v[math.max(1, math.min(#v, rank))]
end
function M.damage(d, rank, stats, tick, distance)
  local amount = M.rank(d.damage, rank) + M.rank(d.attack, rank) * (stats.attack or 0)
    + (d.intellect or 0) * (stats.intellect or 0) + (d.strength or 0) * (stats.strength or 0)
    + (d.agility or 0) * (stats.agility or 0)
  amount = amount * (1 + (d.ramp or 0) * math.max(0, (tick or 1) - 1))
  return amount * (1 + (d.distance_bonus or 0) * math.max(0, math.min(1, distance or 0)))
end
function M.in_line(pos, origin, direction, length, width)
  local dx, dy = pos.x - origin.x, pos.y - origin.y
  local along = dx * direction.x + dy * direction.y
  local side = math.abs(dx * direction.y - dy * direction.x)
  return along >= 0 and along <= length and side <= width, math.max(0, math.min(1, along / math.max(1, length)))
end
function M.clamp_point(point, origin, range)
  local dx, dy = point.x - origin.x, point.y - origin.y
  local length = math.sqrt(dx * dx + dy * dy)
  local scale = length > range and range / length or 1
  return { x = origin.x + dx * scale, y = origin.y + dy * scale, z = point.z or origin.z or 0 }
end
return M
