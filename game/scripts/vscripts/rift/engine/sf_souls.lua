local B=require("rift.data.hero_balance").sf.souls
local M={}
function M.on_death(c)
 if not c or c:IsNull() or c:GetUnitName()~="npc_dota_hero_nevermore" or c:IsIllusion()
  or (c.IsReincarnating and c:IsReincarnating()) then return end
 local now=GameRules:GetGameTime()
 if c._rift_soul_death_time and now-c._rift_soul_death_time<.1 then return end
 c._rift_soul_death_time=now
 local m=c:FindModifierByName("modifier_nevermore_necromastery")
 if not m then return end
 local retained=math.floor(m:GetStackCount()*(1-B.death_loss))
 -- Run on the mode entity: a dead NPC's context thinks can be suspended.
 GameRules:GetGameModeEntity():SetContextThink("rift_sf_death_souls_"..c:entindex(),function()
  if not c:IsNull() then
   local native=c:FindModifierByName("modifier_nevermore_necromastery")
   if native then native:SetStackCount(retained) end
  end
 end,.01)
end
return M
