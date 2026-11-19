-- XY arena geometry shared by engine guards and map validation tests.
local A = {}
function A.inside(p, lo, hi, margin)
  margin = margin or 0
  return p.x >= lo.x + margin and p.x <= hi.x - margin and p.y >= lo.y + margin and p.y <= hi.y - margin
end
function A.clamp(p, lo, hi, margin)
  margin = margin or 0
  return { x = math.max(lo.x + margin, math.min(hi.x - margin, p.x)),
           y = math.max(lo.y + margin, math.min(hi.y - margin, p.y)), z = p.z or 0 }
end
function A.validate(c)
  local errors = {}
  local lo, hi = c.bounds_min, c.bounds_max
  if not lo or not hi or hi.x - lo.x < 1000 or hi.y - lo.y < 1000 then
    return { "invalid arena bounds" }
  end
  for _, group in ipairs({c.spawns or {}, c.relics or {}, {c.center}}) do
    for _, p in ipairs(group) do
      if not A.inside(p,lo,hi,100) then errors[#errors+1] = p.name .. " is outside safe bounds" end
    end
  end
  return errors
end
return A
