modifier_rift_area_items = modifier_rift_area_items or ((type(class) == "function") and class({}) or {})
function modifier_rift_area_items:IsHidden() return true end
function modifier_rift_area_items:IsPurgable() return false end
function modifier_rift_area_items:RemoveOnDeath() return false end
function modifier_rift_area_items:OnCreated()
  if IsServer() then self:OnIntervalThink();self:StartIntervalThink(.1) end
end
function modifier_rift_area_items:OnIntervalThink()
  self:SetStackCount(require("rift.engine.area").item_bonus(self:GetParent()))
end
