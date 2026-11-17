-- Consumables are accepted from main inventory/backpack, never stash/courier.
modifier_rift_aghanim_item = modifier_rift_aghanim_item or ((type(class) == "function") and class({}) or {})
local M=modifier_rift_aghanim_item
function M:IsHidden()return true end
function M:IsPurgable()return false end
function M:GetAttributes()return MODIFIER_ATTRIBUTE_MULTIPLE end
function M:OnCreated()
 if IsServer()then require("rift.engine.aghanim").ensure(self:GetParent());self:StartIntervalThink(.1)end
end
function M:OnIntervalThink()
 local c,a=self:GetParent(),self:GetAbility()
 if not a or a:IsNull()or not c:IsRealHero()or c:IsIllusion()then return end
 local name=a:GetAbilityName();if name=="item_ultimate_scepter"then return end
 local held=false;for i=0,8 do if c:GetItemInSlot(i)==a then held=true end end
 if not held then return end
 local token=name=="item_aghanims_shard"and"modifier_rift_aghanim_shard"or"modifier_rift_aghanim_blessing"
 -- Keep duplicate purchases refundable instead of consuming them for nothing.
 if c:HasModifier(token)then return end
 local m=require("rift.engine.mods").add(c,c,nil,token,{})
 if m then
  local state=require("rift.engine.aghanim").ensure(c)
  if state then state:OnIntervalThink()end
  c:RemoveItem(a)
 end
end
