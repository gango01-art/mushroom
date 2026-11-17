-- Refunds are pooled over one series, not one target/attack record.
local M={}
function M.amount(amount,real_hero,creep_fraction,spent,cap)
 local value=math.max(0,amount)*(real_hero and 1 or creep_fraction)
 return math.min(value,math.max(0,cap-spent))
end
return M
