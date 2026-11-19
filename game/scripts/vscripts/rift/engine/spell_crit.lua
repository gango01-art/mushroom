-- Mutate the original magical spell/item event, never apply a second damage
-- event: no recursion and no duplicate on-damage, lifesteal or item triggers.
local B=require("rift.data.hero_balance").passives
local M={}
function M.filter(ev)
  if ev.damagetype_const~=DAMAGE_TYPE_MAGICAL or not ev.entindex_inflictor_const
    or not ev.entindex_attacker_const or not ev.damage or ev.damage<=0 then return end
  if bit.band(ev.damage_flags or 0,DOTA_DAMAGE_FLAG_REFLECTION)~=0 then return end
  local source=EntIndexToHScript(ev.entindex_inflictor_const)
  if not source or source:IsNull() or not source.GetAbilityName or source:GetAbilityName()=="item_blade_mail" then return end
  local c=EntIndexToHScript(ev.entindex_attacker_const)
  if not c or c:IsNull() or c:IsIllusion() or c:PassivesDisabled() then return end
  local a=c:FindAbilityByName("rift_juggernaut_spell_crit")
  if not a or a:IsNull() or a:GetLevel()<1 then return end
  if RandomInt(1,100)<=B.jug_chance then ev.damage=ev.damage*B.jug_multiplier[a:GetLevel()]/100 end
end
return M
