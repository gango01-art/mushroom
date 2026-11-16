local B=require("rift.data.hero_balance")
modifier_rift_axe_pull = modifier_rift_axe_pull or ((type(class) == "function") and class({}) or {})
function modifier_rift_axe_pull:IsHidden() return true end
function modifier_rift_axe_pull:IsPurgable() return false end
function modifier_rift_axe_pull:OnCreated(kv)
 if not IsServer() then return end
 local p=self:GetParent();local d=Vector(kv.x,kv.y,kv.z)-p:GetAbsOrigin();d.z=0
 self.left=math.min(kv.distance,math.max(0,d:Length2D()-100))
 self.direction=d:Normalized();self.speed=self.left/B.axe.pull_duration
 if self.left<=0 or not self:ApplyHorizontalMotionController() then self:Destroy();return end
 self.fx=ParticleManager:CreateParticle("particles/items_fx/harpoon_pull.vpcf",PATTACH_WORLDORIGIN,self:GetCaster())
end
function modifier_rift_axe_pull:UpdateHorizontalMotion(p,dt)
 if p:IsMagicImmune() or p:IsDebuffImmune() then self:Destroy();return end
 local step=math.min(self.left,self.speed*dt)
 p:SetAbsOrigin(GetGroundPosition(p:GetAbsOrigin()+self.direction*step,p));self.left=self.left-step
 if self.fx then
  ParticleManager:SetParticleControl(self.fx,0,self:GetCaster():GetAbsOrigin()+Vector(0,0,64))
  ParticleManager:SetParticleControl(self.fx,1,p:GetAbsOrigin()+Vector(0,0,64))
 end
 if self.left<=.1 then self:Destroy() end
end
function modifier_rift_axe_pull:OnHorizontalMotionInterrupted() self:Destroy() end
function modifier_rift_axe_pull:CheckState() return {[MODIFIER_STATE_NO_UNIT_COLLISION]=true} end
function modifier_rift_axe_pull:OnDestroy()
 if not IsServer() then return end
 local p=self:GetParent();p:RemoveHorizontalMotionController(self)
 if self.fx then ParticleManager:DestroyParticle(self.fx,false);ParticleManager:ReleaseParticleIndex(self.fx) end
 if not p:IsNull() then FindClearSpaceForUnit(p,p:GetAbsOrigin(),true) end
end
