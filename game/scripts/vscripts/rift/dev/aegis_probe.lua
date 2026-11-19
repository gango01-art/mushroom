local gm=GameRules.RiftArena;local s=gm.roshan;local h=PlayerResource:GetSelectedHeroEntity(0)
assert(gm.dev and PlayerResource:GetPlayerCount()==1 and not gm.lab.enabled)
assert(s.aegis and not s.aegis:IsNull(),"real dropped Aegis required")
local function log(t)print("[RIFT][AEGIS_PROBE] "..t)end
for i=0,8 do local a=h:GetItemInSlot(i);if a then log("slot="..i.." item="..a:GetAbilityName())end end
FindClearSpaceForUnit(h,s.aegis:GetAbsOrigin()+Vector(90,0,0),true);h:Stop();PlayerResource:SetCameraTarget(0,h)
ExecuteOrderFromTable({UnitIndex=h:entindex(),OrderType=DOTA_UNIT_ORDER_PICKUP_ITEM,TargetIndex=s.aegis:entindex(),Queue=false})
local phase="pickup";local at=GameRules:GetGameTime()+3;local origin,deaths,deadline
GameRules:GetGameModeEntity():SetContextThink("rift_aegis_probe",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime();if now<at then return .1 end
  if phase=="pickup"then
   assert(h:HasModifier("modifier_item_aegis"),"native pickup order failed")
   origin=h:GetAbsOrigin();deaths=gm.scoring:get(0).deaths;deadline=now+10
   log("real native pickup order PASS");h:Kill(nil,nil);phase="rebirth";at=now+.2
  elseif phase=="rebirth"then
   if not h:IsAlive()then assert(now<deadline,"Aegis rebirth timeout");at=now+.1;return .1 end
   assert((h:GetAbsOrigin()-origin):Length2D()<150,"reincarnation teleported to home")
   assert(gm.scoring:get(0).deaths==deaths,"Aegis counted as PvP death")
   log("native rebirth in place, no PvP death PASS; DONE")
   local ok,e=pcall(require,"rift.dev.relic_probe");if not ok then log("relic start ERROR "..tostring(e))end
   return nil
  end
  return .1
 end)
 if not ok then log("ERROR "..tostring(result));PlayerResource:SetCameraTarget(0,nil);return nil end
 return result
end,.1)
