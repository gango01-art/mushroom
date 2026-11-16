-- Native cooldown/mana queries use -1 for the current level; explicit preview
-- queries use zero-based indices. Treating -1 as rank 1 breaks real casts.
return function(ability,index)
  if index==nil or index<0 then return math.max(1,ability:GetLevel()) end
  return index+1
end
