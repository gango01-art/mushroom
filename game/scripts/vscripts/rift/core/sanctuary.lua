-- Pure sanctuary geometry. Damage protection uses impact-time positions.
local M={}
function M.contains(base,pos,radius)
 if not base or not pos then return false end
 local x,y=pos.x-base.x,pos.y-base.y
 return x*x+y*y<=radius*radius
end
function M.home(bases,team)
 for _,base in ipairs(bases or{})do if base.team==team then return base end end
end
function M.sheltered(bases,team,pos,radius)
 return M.contains(M.home(bases,team),pos,radius)
end
return M
