-- Native player-owned couriers, one per FFA player; no hero-owned inventory proxy.
local Mods=require("rift.engine.mods")
local Log=require("rift.engine.log")
local M={}
function M.ensure(gm,hero,pid)
 gm.couriers=gm.couriers or{}
 local u=gm.couriers[pid]
 if not u or u:IsNull()then
  u=Log.try(PlayerResource,"Courier","GetNthCourierForTeam",0,hero:GetTeamNumber())
 end
 if not u or u:IsNull()then
  local player=PlayerResource:GetPlayer(pid)
  if not player then return end
  u=Log.try(player,"Courier","SpawnCourierAtPosition",hero:GetAbsOrigin())
 end
 if not u or u:IsNull()then Log.error("COURIER","spawn failed pid="..pid);return end
 gm.couriers[pid]=u
 u:SetControllableByPlayer(pid,true)
 if not u:HasModifier("modifier_rift_courier")then Mods.add(u,u,nil,"modifier_rift_courier",{})end
 Log.info("COURIER","ready pid="..pid.." entity="..u:entindex())
 return u
end
return M
