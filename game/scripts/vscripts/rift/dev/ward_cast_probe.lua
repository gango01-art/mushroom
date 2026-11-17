local gm=GameRules.RiftArena;assert(gm.dev and PlayerResource:GetPlayerCount()==1)
local h=PlayerResource:GetSelectedHeroEntity(0);local p=gm.map.ward_spots[1]
local item=assert(h:FindItemInInventory("item_ward_observer"))
FindClearSpaceForUnit(h,Vector(p.x-250,p.y-250,128),true);h:Stop();PlayerResource:SetCameraTarget(0,h)
local function log(s)print("[RIFT][WARD_CAST] "..s)end
for i=0,8 do local a=h:GetItemInSlot(i);if a and not a:IsNull()then log("slot="..i.." name="..a:GetAbilityName().." ready="..tostring(a:IsFullyCastable()).." cooldown="..a:GetCooldownTimeRemaining())end end
log("stunned="..tostring(h:IsStunned()).." commandrestricted="..tostring(h:IsCommandRestricted()))
local phase=0
GameRules:GetGameModeEntity():SetContextThink("rift_ward_cast_probe",function()
 phase=phase+1
 if phase==1 then
  log("casting TOP ground="..GetGroundPosition(Vector(p.x,p.y,p.z),nil).z.." traversable="..tostring(GridNav:IsTraversable(Vector(p.x,p.y,p.z))))
  h:CastAbilityOnPosition(Vector(p.x,p.y,p.z),item,0);return 3
 elseif phase==2 then
  log("after TOP charges="..item:GetCurrentCharges().." hero="..tostring(h:GetAbsOrigin()))
  h:Stop();h:CastAbilityOnPosition(h:GetAbsOrigin()+Vector(70,0,0),item,0);return 3
 else log("after FLOOR charges="..item:GetCurrentCharges());return nil end
end,.5)
