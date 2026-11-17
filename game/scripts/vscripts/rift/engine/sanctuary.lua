local B=require("rift.core.config").sanctuary
local Core=require("rift.core.sanctuary")
local Mods=require("rift.engine.mods")
local Log=require("rift.engine.log")
local M={};M.__index=M
local function valid(u)return u and not u:IsNull()end
function M.new(gm)
 return setmetatable({gm=gm,bases=gm.map and not gm.map.fallback and gm.map.bases or{},towers={},thinkers={},rings={}},M)
end
function M:home(team)return Core.home(self.bases,team)end
function M:sheltered(u)
 if not valid(u)or not u.GetPlayerOwnerID or u:GetPlayerOwnerID()<0 then return false end
 return Core.sheltered(self.bases,u:GetTeamNumber(),u:GetAbsOrigin(),B.radius)
end
function M:outgoing_protected(u)
 if not valid(u)or not u.GetPlayerOwnerID then return false end
 local pid=u:GetPlayerOwnerID();if pid<0 then return false end
 if self:sheltered(u)then return true end
 -- A hero cannot send damage/debuffs through a summon parked outside its base.
 local hero=PlayerResource:GetSelectedHeroEntity(pid)
 return valid(hero)and self:sheltered(hero)or false
end
function M:filter_damage(ev)
 local victim=ev.entindex_victim_const and EntIndexToHScript(ev.entindex_victim_const)
 local attacker=ev.entindex_attacker_const and EntIndexToHScript(ev.entindex_attacker_const)
 return not self:sheltered(victim)and not self:outgoing_protected(attacker)
end
function M:filter_modifier(ev)
 local u=ev.entindex_parent_const and EntIndexToHScript(ev.entindex_parent_const)
 local c=ev.entindex_caster_const and EntIndexToHScript(ev.entindex_caster_const)
 if not valid(u)or not valid(c)or u:GetTeamNumber()==c:GetTeamNumber()then return true end
 return not self:sheltered(u)and not self:outgoing_protected(c)
end
function M:start()
 for _,base in ipairs(self.bases)do
  local p=base.tower
  local tower_origin=GetGroundPosition(Vector(p.x,p.y,p.z),nil)
  local tower=CreateUnitByName(B.tower_unit,tower_origin,false,nil,nil,base.team)
  if valid(tower)then
   -- Native tower creation ignores the requested origin; place it explicitly.
   tower:SetAbsOrigin(tower_origin)
   tower:SetBaseDamageMin(B.tower_damage);tower:SetBaseDamageMax(B.tower_damage)
   tower:SetBaseAttackTime(B.tower_attack_rate);tower:SetAcquisitionRange(B.tower_range)
   Mods.add(tower,tower,nil,"modifier_rift_base_guardian",{})
   self.towers[base.team]=tower
   local origin=GetGroundPosition(Vector(base.x,base.y,base.z),nil)
   self.thinkers[base.team]=CreateModifierThinker(tower,nil,"modifier_rift_sanctuary_aura",{},origin,base.team,false)
   local ring=ParticleManager:CreateParticleForTeam("particles/ui_mouseactions/range_display.vpcf",PATTACH_WORLDORIGIN,nil,base.team)
   ParticleManager:SetParticleControl(ring,0,origin);ParticleManager:SetParticleControl(ring,1,Vector(B.radius,0,0))
   self.rings[base.team]=ring
  else Log.error("BASE","guardian spawn failed team="..base.team)end
 end
 Log.info("BASE","sanctuaries="..#self.bases.."; own-base damage and hostile effects blocked in both directions")
end
return M
