-- The installed Counter Helix exposes attacks_increase_counter (native Scepter
-- behavior). Reuse that engine path instead of fabricating extra attack events.
modifier_rift_axe_helix = modifier_rift_axe_helix or ((type(class) == "function") and class({}) or {})
function modifier_rift_axe_helix:IsHidden() return true end
function modifier_rift_axe_helix:IsPurgable() return false end
function modifier_rift_axe_helix:RemoveOnDeath() return false end
function modifier_rift_axe_helix:OnCreated()
 if IsServer() then
  local m=self:GetParent():FindModifierByName("modifier_axe_counter_helix")
  if m then m:ForceRefresh() end
 end
end
function modifier_rift_axe_helix:DeclareFunctions()
 return {MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE}
end
local function applies(ev)
 return ev.ability and not ev.ability:IsNull() and ev.ability:GetAbilityName()=="axe_counter_helix"
  and (ev.ability_special_value=="trigger_attacks" or ev.ability_special_value=="attacks_increase_counter")
end
function modifier_rift_axe_helix:GetModifierOverrideAbilitySpecial(ev) return applies(ev) and 1 or 0 end
function modifier_rift_axe_helix:GetModifierOverrideAbilitySpecialValue(ev)
 if not applies(ev) then return 0 end
 if ev.ability_special_value=="attacks_increase_counter" then return 1 end
 local rank=ev.ability_special_level and ev.ability_special_level>=0 and ev.ability_special_level+1 or ev.ability:GetLevel()
 return require("rift.data.hero_balance").axe.helix_attacks[math.max(1,math.min(4,rank))]
end
