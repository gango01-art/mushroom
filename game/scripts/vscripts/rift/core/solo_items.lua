local M={}
-- One copy of the strongest item in each upgrade family. Backpack/stash is
-- excluded by the adapter. Stable slot ordering breaks equal-cost ties.
function M.selected(entries,definitions)
 local families,out={},{}
 for _,e in ipairs(entries)do
  local d=definitions[e.name]
  if d then
   local old=families[d.family]
   if not old or d.cost>definitions[old.name].cost then families[d.family]=e end
  end
 end
 for _,e in pairs(families)do out[e.id]=true end
 return out
end
function M.block(pool,damage,kind,wanted)
 if damage<=0 or kind~=wanted then return 0,pool end
 local blocked=math.min(math.max(0,pool),damage)
 return blocked,pool-blocked
end
function M.heal(active,max_health)
 return (active.heal or 0)+math.min(active.heal_pct_cap or 0,max_health*(active.heal_max_health_pct or 0)/100)
end
return M
