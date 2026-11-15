-- Laboratory targets retain enemy hero classification, allowing hero-only R tests.
modifier_rift_lab_target = modifier_rift_lab_target or ((type(class) == "function") and class({}) or {})
function modifier_rift_lab_target:IsHidden() return false end
function modifier_rift_lab_target:IsPurgable() return false end
function modifier_rift_lab_target:RemoveOnDeath() return false end
function modifier_rift_lab_target:GetTexture() return "item_ward_observer" end
function modifier_rift_lab_target:OnCreated(kv)
  if IsServer() then
    self:SetStackCount(kv.kind=="mortal" and 0 or kv.kind=="immune" and 2 or 1)
  end
end
function modifier_rift_lab_target:DeclareFunctions() return { MODIFIER_PROPERTY_MIN_HEALTH } end
function modifier_rift_lab_target:GetMinHealth() return self:GetStackCount()>0 and 1 or 0 end
function modifier_rift_lab_target:CheckState()
  return { [MODIFIER_STATE_ROOTED]=true,[MODIFIER_STATE_DISARMED]=true,
    [MODIFIER_STATE_SILENCED]=true,[MODIFIER_STATE_MUTED]=true,
    [MODIFIER_STATE_COMMAND_RESTRICTED]=true,[MODIFIER_STATE_PASSIVES_DISABLED]=true,
    [MODIFIER_STATE_DEBUFF_IMMUNE]=self:GetStackCount()==2,
    [MODIFIER_STATE_MAGIC_IMMUNE]=self:GetStackCount()==2 }
end
