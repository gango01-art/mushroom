-- Native talent slots, path state and inventory-backed branch bonuses.
local B=require("rift.data.hero_balance").progression
local Core=require("rift.core.progression")
local M={}
function M.name(hero,path,index)
 return "special_bonus_duality_"..hero:gsub("npc_dota_hero_","").."_"..path.."_"..index
end
function M.definition(unit)
 if not unit or unit:IsNull() or unit:IsIllusion() then return nil end
 local hero=B.heroes[unit:GetUnitName()]
 if not hero then return nil end
 local stack=unit:GetModifierStackCount("modifier_rift_progression",unit)
 local path=({[1]="physical",[2]="magical"})[stack]
 return path and hero[path],path
end
function M.totals(unit)
 local def,path=M.definition(unit)
 if not def then return {} end
 local learned={}
 for i=1,#def.talents do
  local a=unit:FindAbilityByName(M.name(unit:GetUnitName(),path,i))
  learned[i]=a and a:GetLevel()>0 or false
 end
 return Core.total(def,learned,unit:HasScepter(),unit:HasModifier("modifier_item_aghanims_shard"))
end
function M.get(unit,key)return M.totals(unit)[key]or 0 end
function M.can_train(unit,path,index)
 local def,current=M.definition(unit)
 if not def or current~=path then return false end
 local other=unit:FindAbilityByName(M.name(unit:GetUnitName(),path,index%2==1 and index+1 or index-1))
 return Core.can_learn(B,unit:GetLevel(),math.ceil(index/2),other and other:GetLevel()>0)
end
function M.primary(unit,ability)
 local d=M.definition(unit);return d and ability and d.ult==ability:GetAbilityName()
end
function M.cooldown(unit,ability,base,flat)
 return M.primary(unit,ability)and Core.cooldown(base,M.totals(unit),B,flat)or math.max(1,base-(flat or 0))
end
function M.radius(unit,ability,base)
 return M.primary(unit,ability)and Core.radius(base,M.totals(unit),B)or base
end
function M.profile(unit,ability,base)
 return M.primary(unit,ability)and Core.profile(base,M.totals(unit),B)or base
end
function M.ensure(unit,path)
 if not B.heroes[unit:GetUnitName()]or unit:IsIllusion()then return end
 local m=unit:FindModifierByName("modifier_rift_progression")
   or require("rift.engine.mods").add(unit,unit,nil,"modifier_rift_progression",{})
 if not path then return end
 -- Swapping preserves native talent slots and already learned ranks. The mode
 -- never offers path changes in a normal match; lab replacements are new heroes.
 for i=1,8 do
  local wanted=M.name(unit:GetUnitName(),path,i)
  local other=M.name(unit:GetUnitName(),path=="physical"and"magical"or"physical",i)
  local old=unit:FindAbilityByName(other)
  if old and (not unit:FindAbilityByName(wanted)or not old:IsHidden())then
   local a=unit:FindAbilityByName(wanted)or unit:AddAbility(wanted)
   if a then
    local level=old:GetLevel();unit._rift_progression_transfer=true
    unit:SwapAbilities(other,wanted,false,true);old:SetLevel(0);a:SetLevel(level)
    unit._rift_progression_transfer=nil
    -- Native stat-branch UI enumerates hidden attribute abilities as well and
    -- crashes on a ninth talent (UpgradeName9). Keep exactly eight on the unit.
    unit:RemoveAbility(other)
   end
  end
 end
 if m then m:SetStackCount(path=="physical"and 1 or 2)end
end
return M
