local B=require("rift.core.config").river_camps
local Core=require("rift.core.river_camps")
local Mods=require("rift.engine.mods")
local M={};M.__index=M
function M.new(gm)
 local self=setmetatable({gm=gm,camps={}},M)
 if not gm.map.fallback then for i,p in ipairs(gm.map.river_camps or{})do self.camps[i]={point=p,remaining=0,units={}}end end
 return self
end
function M:spawn(camp,elapsed)
 local p=camp.point;local scale=Core.scale(B,elapsed)
 local origin=GetGroundPosition(Vector(p.x,p.y,p.z),nil)
 if not GridNav:IsTraversable(origin)or GridNav:IsBlocked(origin)or not GridNav:CanFindPath(Vector(self.gm.map.center.x,self.gm.map.center.y,self.gm.map.center.z),origin)then
  require("rift.engine.log").error("RIVER","camp unreachable "..p.name);camp.ready_at=self.gm:Now()+B.respawn_seconds;return
 end
 camp.units={};camp.remaining=0
 for _,d in ipairs(B.members)do
  local unit=CreateUnitByName(d.unit,origin+Vector(d.dx,d.dy,0),true,nil,nil,DOTA_TEAM_NEUTRALS)
  if unit and not unit:IsNull()then
   unit:SetBaseMaxHealth(math.floor(d.health*scale));unit:SetMaxHealth(math.floor(d.health*scale));unit:SetHealth(unit:GetMaxHealth())
   unit:SetBaseDamageMin(math.floor(d.damage*scale));unit:SetBaseDamageMax(math.floor(d.damage*scale))
   unit._rift_river={camp=camp,gold=math.floor(d.gold*scale),xp=math.floor(d.xp*scale),origin=origin}
   Mods.add(unit,unit,nil,"modifier_rift_river_neutral",{})
   camp.units[#camp.units+1]=unit;camp.remaining=camp.remaining+1
  end
 end
 require("rift.engine.log").info("RIVER",p.name.." spawned="..camp.remaining.." scale="..scale)
end
function M:tick(now,elapsed)
 for _,c in ipairs(self.camps)do if Core.ready(c,now,elapsed,B)then self:spawn(c,elapsed)end end
end
function M:on_killed(unit,attacker)
 local r=unit and unit._rift_river;if not r then return false end
 if r.paid then return true end;r.paid=true;Core.killed(r.camp,self.gm:Now(),B)
 local pid=attacker and attacker.GetPlayerOwnerID and attacker:GetPlayerOwnerID()or -1
 if pid>=0 and self.gm.players[pid]and self.gm.director.state:is("ACTIVE")and not self.gm.lab.enabled then self.gm:Grant(pid,r.gold,r.xp)end
 return true
end
function M:stop()
 for _,c in ipairs(self.camps)do for _,u in ipairs(c.units)do if u and not u:IsNull()then UTIL_Remove(u)end end;c.units={};c.remaining=0 end
end
return M
