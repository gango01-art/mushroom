local B=require("rift.core.config").roshan
local Core=require("rift.core.roshan")
local Mods=require("rift.engine.mods")
local Log=require("rift.engine.log")
local M={};M.__index=M
local function valid(u)return u and not u:IsNull()and u:IsAlive()end
function M.new(gm)return setmetatable({gm=gm,pockets=gm.map.fallback and{}or gm.map.roshan_pockets or{},paid=false},M)end
function M:spawn(elapsed)
 if not self.torch_fx then
  self.torch_fx={}
  for pit=1,2 do for side=1,2 do
   local prop=Entities:FindByName(nil,"rift_pit_"..pit.."_torch_"..side)
   if prop and not prop:IsNull()then
    local fx=ParticleManager:CreateParticle(B.torch_particle,PATTACH_POINT_FOLLOW,prop)
    ParticleManager:SetParticleControlEnt(fx,0,prop,PATTACH_POINT_FOLLOW,"flame_attach",prop:GetAbsOrigin(),true)
    self.torch_fx[#self.torch_fx+1]=fx
   end
  end end
 end
 self.index=Core.pocket(B,elapsed);local p=self.pockets[self.index]
 if not p then return end
 local at=GetGroundPosition(Vector(p.x,p.y,p.z),nil)
 if not GridNav:IsTraversable(at)or GridNav:IsBlocked(at)then Log.error("ROSHAN","pocket blocked "..self.index);return end
 local u=CreateUnitByName(B.unit,at,true,nil,nil,DOTA_TEAM_NEUTRALS);if not u or u:IsNull()then return end
 local scale=Core.scale(B,elapsed);u:SetBaseMaxHealth(math.floor(B.health*scale));u:SetMaxHealth(math.floor(B.health*scale));u:SetHealth(u:GetMaxHealth())
 u:SetBaseDamageMin(math.floor(B.damage*scale));u:SetBaseDamageMax(math.floor(B.damage*scale))
 self.unit=u;self.paid=false;self.travelling=false;self.target_index=nil;self.last_combat=nil;self.slam_scale=scale
 u._rift_roshan=self;u:SetIdleAcquire(false);Mods.add(u,u,nil,"modifier_rift_roshan",{})
 for _,name in ipairs(B.abilities)do
  local a=u:FindAbilityByName(name);if a then a:SetLevel(1)else Log.error("ROSHAN","native ability missing "..name)end
 end
 local id=ParticleManager:CreateParticle(B.spawn_particle,PATTACH_WORLDORIGIN,u);ParticleManager:SetParticleControl(id,0,u:GetAbsOrigin());ParticleManager:ReleaseParticleIndex(id)
 Log.info("ROSHAN","spawn pocket="..self.index.." hp="..u:GetMaxHealth())
end
function M:travel_to(index)
 if not valid(self.unit)or index==self.index or self.travelling then return false end
 local p=self.pockets[index];if not p then return false end
 self.target_index=index;self.travelling=true;self.throw_count=0;self.destination=GetGroundPosition(Vector(p.x,p.y,p.z),nil)
 self.unit:Stop()
 self.unit:MoveToPosition(self.destination)
 Log.info("ROSHAN","walking "..self.index.." -> "..index);return true
end
function M:tick(now,elapsed)
 if #self.pockets~=2 or self.stopped then return end
 if not valid(self.unit)then
  if not self.respawn_at or now>=self.respawn_at then self:spawn(elapsed)end
  return
 end
 if self.travelling and(self.unit:GetAbsOrigin()-self.destination):Length2D()<140 then
  self.index=self.target_index;self.travelling=false;self.target_index=nil;self.unit:Stop()
  Log.info("ROSHAN","arrived pocket="..self.index)
 end
 local wanted=Core.pocket(B,elapsed)
 if not self.travelling and wanted~=self.index then self:travel_to(wanted)end
 for _,team in ipairs(self.gm.teams)do AddFOWViewer(team,self.unit:GetAbsOrigin(),B.reveal_radius,B.reveal_duration,false)end
end
function M:on_killed(unit,attacker)
 if not unit or unit._rift_roshan~=self then return false end
 if self.paid then return true end;self.paid=true;self.respawn_at=self.gm:Now()+B.respawn_seconds;self.unit=nil;self.travelling=false
 if not self.gm.director.state:is("ACTIVE")or self.gm.lab.enabled then return true end
 local aegis=CreateItem("item_aegis",nil,nil)
 self.aegis=CreateItemOnPositionSync(unit:GetAbsOrigin(),aegis)
 local pid=attacker and attacker.GetPlayerOwnerID and attacker:GetPlayerOwnerID()or -1
 if pid>=0 and self.gm.players[pid]then self.gm:Grant(pid,B.gold,0)end
 Log.info("ROSHAN","killed: aegis=1 gold="..(pid>=0 and B.gold or 0).." respawn_in="..B.respawn_seconds)
 return true
end
function M:view(now,elapsed)
 if #self.pockets~=2 or self.stopped or not self.gm.director.state:is("ACTIVE")then return {disabled=1}end
 local p=valid(self.unit)and self.unit:GetAbsOrigin()or self.pockets[self.index or 1]
 return {x=p.x,y=p.y,z=p.z,alive=valid(self.unit)and 1 or 0,pocket=self.index or 1,moving=self.travelling and 1 or 0,target=self.target_index or 0,
 next_move=math.max(0,math.ceil(Core.next_move(B,elapsed)-elapsed)),respawn=math.max(0,math.ceil((self.respawn_at or now)-now))}
end
function M:stop()
 self.stopped=true
 for _,fx in ipairs(self.torch_fx or{})do ParticleManager:DestroyParticle(fx,true);ParticleManager:ReleaseParticleIndex(fx)end
 self.torch_fx=nil
 if self.unit and not self.unit:IsNull()then UTIL_Remove(self.unit)end;self.unit=nil
end
return M
