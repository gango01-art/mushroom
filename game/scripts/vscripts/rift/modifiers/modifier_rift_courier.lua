modifier_rift_courier = modifier_rift_courier or ((type(class) == "function") and class({}) or {})
local M=modifier_rift_courier
function M:IsHidden()return true end
function M:IsPurgable()return false end
function M:RemoveOnDeath()return false end
function M:CheckState()
 local enemy=false
 if not IsServer()then
  local p=Entities:GetLocalPlayer()
  enemy=p and p:GetPlayerID()~=self:GetParent():GetPlayerOwnerID()or false
 end
 return {[MODIFIER_STATE_INVULNERABLE]=true,[MODIFIER_STATE_NO_HEALTH_BAR]=true,
 [MODIFIER_STATE_NO_UNIT_COLLISION]=true,[MODIFIER_STATE_UNSELECTABLE]=enemy,
 [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES]=true}
end
