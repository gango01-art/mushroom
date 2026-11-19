-- DUALITY ownership deliberately does not set native HasScepter(). Native
-- C++ abilities would otherwise enable their unrelated stock upgrades too.
local M={}
function M.scepter(unit)
 return unit and unit:GetModifierStackCount("modifier_rift_aghanim_state",unit)%2==1 or false
end
function M.shard(unit)return unit and unit:HasModifier("modifier_rift_aghanim_shard")or false end
function M.ensure(unit)
 return unit:FindModifierByName("modifier_rift_aghanim_state")
  or require("rift.engine.mods").add(unit,unit,nil,"modifier_rift_aghanim_state",{})
end
return M
