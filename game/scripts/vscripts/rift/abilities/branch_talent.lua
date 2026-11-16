-- Each generated native attribute ability is a one-rank choice. Effects are
-- resolved from its learned level by modifier_rift_progression on both VMs.
local P=require("rift.engine.progression")
local B=require("rift.data.hero_balance").progression
for hero,paths in pairs(B.heroes)do for path,d in pairs(paths)do for i=1,#d.talents do
 local name=P.name(hero,path,i)
 local A=_G[name]or((type(class)=="function")and class({})or{});_G[name]=A
 local chosen_path,index=path,i
 function A:OnUpgrade()
  if not IsServer()or self:GetLevel()<1 then return end
  local c=self:GetCaster()
  local gm=GameRules.RiftArena
  -- ReplaceHeroWith can copy learned talents before the new hero's level/path
  -- are initialized. Never refund or unlearn during that native construction.
  if c._rift_progression_transfer or self._rift_upgrade_refund
   or (gm and gm.lab and gm.lab.loading)or not P.definition(c)then return end
  if not P.can_train(c,chosen_path,index)then
   self._rift_upgrade_refund=true
   self:SetLevel(0);c:SetAbilityPoints(c:GetAbilityPoints()+1)
   self._rift_upgrade_refund=nil
   print("[RIFT][TALENT] rejected locked choice "..self:GetAbilityName())
  end
 end
end end end
