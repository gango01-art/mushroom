local B=require("rift.core.config").center_gold
local Core=require("rift.core.center_gold")
local Mods=require("rift.engine.mods")
local M={};M.__index=M
local function valid(u)return u and not u:IsNull()end
function M.new(gm)return setmetatable({gm=gm,credits={},inside={},splashes={},positions={}},M)end
function M:vision()
 if not B.public_vision or self.gm.map.fallback or self.stopped then return end
 local p=self.gm.map.center
 for _,team in ipairs(self.gm.teams or{})do AddFOWViewer(team,Vector(p.x,p.y,p.z),B.radius+B.vision_margin,B.vision_duration,false)end
 for pid in pairs(self.gm.players)do
  local u=PlayerResource:GetSelectedHeroEntity(pid)
  local inside=valid(u)and u:IsAlive()and Core.inside(self.gm.map.center,u:GetAbsOrigin(),B.radius)
  local s=self.splashes[pid]
  if inside then
   if not s then s=ParticleManager:CreateParticle(B.splash_particle,PATTACH_ABSORIGIN_FOLLOW,u);self.splashes[pid]=s end
   local pos=u:GetAbsOrigin();local old=self.positions[pid]
   ParticleManager:SetParticleControl(s,1,Vector(old and (pos-old):Length2D()>1 and .55 or 0,0,0));self.positions[pid]=pos
  elseif s then ParticleManager:DestroyParticle(s,false);ParticleManager:ReleaseParticleIndex(s);self.splashes[pid]=nil;self.positions[pid]=nil end
 end
end
function M:stop()
 self.stopped=true
 for pid,id in pairs(self.splashes)do ParticleManager:DestroyParticle(id,true);ParticleManager:ReleaseParticleIndex(id);self.splashes[pid]=nil end
 for pid,u in pairs(self.inside)do if valid(u)then u:RemoveModifierByName("modifier_rift_center_gold")end;self.inside[pid]=nil end
end
function M:tick(first,last)
 if self.gm.map.fallback then return end
 local pids,units={},{}
 for pid in pairs(self.gm.players)do
  local u=PlayerResource:GetSelectedHeroEntity(pid)
  if valid(u)and u:IsAlive()and u:IsRealHero()and not u:IsIllusion()and Core.inside(self.gm.map.center,u:GetAbsOrigin(),B.radius)then
   pids[#pids+1]=pid;units[pid]=u
   if not u:HasModifier("modifier_rift_center_gold")then Mods.add(u,u,nil,"modifier_rift_center_gold",{})end
  end
 end
 table.sort(pids)
 for pid,u in pairs(self.inside)do if units[pid]~=u and valid(u)then u:RemoveModifierByName("modifier_rift_center_gold")end end
 self.inside=units
 for pid,gold in pairs(Core.distribute(self.credits,pids,B.phases,first,last))do if gold>0 then self.gm:Grant(pid,gold,0)end end
end
return M
