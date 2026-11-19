-- LC physical Duel: Legion Commander on the throne. Invulnerable, cannot move, attack,
-- cast or use items while her champion fights. Removed only by the session cleanup
-- (engine/lc_duel_session); the duration is a safety net against a lost session.
modifier_rift_lc_throne = modifier_rift_lc_throne or ((type(class) == "function") and class({}) or {})
function modifier_rift_lc_throne:IsHidden() return false end
function modifier_rift_lc_throne:IsPurgable() return false end
function modifier_rift_lc_throne:IsPurgeException() return false end
function modifier_rift_lc_throne:GetTexture() return "legion_commander_duel" end
function modifier_rift_lc_throne:OnCreated()
  if not IsServer() then return end
  local p=self:GetParent()
  self.origin=p:GetAbsOrigin();self.facing=p:GetForwardVector();self.angle=0
  self.fx=ParticleManager:CreateParticle("particles/items_fx/cyclone.vpcf",PATTACH_ABSORIGIN_FOLLOW,p)
  p:StartGesture(ACT_DOTA_FLAIL)
  self:StartIntervalThink(.03)
end
function modifier_rift_lc_throne:OnIntervalThink()
  local p=self:GetParent();local b=require("rift.data.hero_balance").lc.duel_physical
  self.angle=self.angle+b.cyclone_turn_speed*.03*math.pi/180
  p:SetAbsOrigin(self.origin+Vector(0,0,b.cyclone_height))
  p:SetForwardVector(Vector(math.cos(self.angle),math.sin(self.angle),0))
end
function modifier_rift_lc_throne:OnDestroy()
  if not IsServer() then return end
  local p=self:GetParent()
  if self.fx then ParticleManager:DestroyParticle(self.fx,false);ParticleManager:ReleaseParticleIndex(self.fx) end
  if not p:IsNull() then
    p:RemoveGesture(ACT_DOTA_FLAIL)
    if self.facing then p:SetForwardVector(self.facing) end
    if self.origin then FindClearSpaceForUnit(p,self.origin,true) end
  end
end
function modifier_rift_lc_throne:CheckState()
  return { [MODIFIER_STATE_INVULNERABLE] = true, [MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_DISARMED] = true,
           [MODIFIER_STATE_SILENCED] = true, [MODIFIER_STATE_MUTED] = true,
           [MODIFIER_STATE_COMMAND_RESTRICTED] = true }
end
