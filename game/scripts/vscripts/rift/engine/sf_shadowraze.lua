-- Shared native Shadowraze mark for custom Requiem eruptions.
local M={}
function M.bonus(caster,target)
  local a=caster:FindAbilityByName("nevermore_shadowraze1")
  local mod=target:FindModifierByName("modifier_nevermore_shadowraze_debuff")
  return a and a:GetLevel()>0 and mod and a:GetSpecialValueFor("stack_bonus_damage")*mod:GetStackCount() or 0
end
function M.mark(caster,target)
  local a=caster:FindAbilityByName("nevermore_shadowraze1")
  if not a or a:GetLevel()<1 then return end
  local duration=a:GetSpecialValueFor("duration")*(1-target:GetStatusResistance())
  local name="modifier_nevermore_shadowraze_debuff"
  local previous=target:FindModifierByName(name)
  local count=previous and previous:GetStackCount() or 0
  local mod=target:AddNewModifier(caster,a,name,{duration=duration})
  if mod then mod:SetStackCount(count+1) end
end
function M.souls(caster)
  local mod=caster:FindModifierByName("modifier_rift_sf_soul_gain")
  if mod then mod:AddSouls(require("rift.data.hero_balance").sf.souls.per_raze) end
end
return M
