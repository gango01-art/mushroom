-- Four orthogonal XY rays; a stationary/zero aim has a deterministic fallback.
local C={}
function C.directions(direction)
  local x,y=direction.x or 0,direction.y or 0
  local len=math.sqrt(x*x+y*y)
  if len<0.01 then x,y=1,0 else x,y=x/len,y/len end
  return {{x=x,y=y},{x=-y,y=x},{x=-x,y=-y},{x=y,y=-x}}
end
return C
