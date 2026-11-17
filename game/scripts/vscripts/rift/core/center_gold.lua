local Rules=require("rift.core.rules")
local M={}
function M.inside(center,point,radius)
 return center and point and (center.x-point.x)^2+(center.y-point.y)^2<=radius*radius or false
end
function M.distribute(credits,pids,phases,first,last)
 local paid={};if #pids==0 then return paid end
 local share=Rules.income_between(phases,first,last)/#pids
 for _,pid in ipairs(pids)do
  local credit=(credits[pid]or 0)+share
  local gold=math.floor(credit+1e-9)
  credits[pid]=math.max(0,credit-gold);paid[pid]=gold
 end
 return paid
end
return M
