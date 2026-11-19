local B=require("rift.core.config").sanctuary
modifier_rift_base_guardian = modifier_rift_base_guardian or ((type(class) == "function") and class({}) or {})
local M=modifier_rift_base_guardian
function M:IsHidden()return true end
function M:IsPurgable()return false end
function M:OnCreated()
 if IsServer()then self:GetParent():SetIdleAcquire(false);self:StartIntervalThink(B.guardian_think)end
end
function M:OnIntervalThink()
 local tower=self:GetParent();local gm=GameRules.RiftArena
 local base=gm and gm.sanctuary and gm.sanctuary:home(tower:GetTeamNumber())
 if not base then return end
 local targets=FindUnitsInRadius(tower:GetTeamNumber(),tower:GetAbsOrigin(),nil,B.tower_range,
  DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC,
  DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES+DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,FIND_CLOSEST,false)
 local target
 for _,u in ipairs(targets)do
  if not u:IsInvulnerable()and require("rift.core.sanctuary").contains(base,u:GetAbsOrigin(),B.radius+B.guardian_buffer)then target=u;break end
 end
 if target then
  if tower:GetAttackTarget()~=target then tower:MoveToTargetToAttack(target)end
 elseif tower:GetAttackTarget()then tower:Stop()end
end
function M:CheckState()return {[MODIFIER_STATE_INVULNERABLE]=true,[MODIFIER_STATE_NO_HEALTH_BAR]=true}end
function M:DeclareFunctions()return {MODIFIER_EVENT_ON_ATTACK_LANDED}end
function M:OnAttackLanded(ev)
 if not IsServer()or ev.attacker~=self:GetParent()or not ev.target or ev.target:IsNull()then return end
 local tower=self:GetParent();local target=ev.target
 if target:GetTeamNumber()==tower:GetTeamNumber()or target:IsBuilding()or target:IsOther()then return end
 local p=tower:GetAbsOrigin()
 local m=target:AddNewModifier(tower,nil,"modifier_knockback",{duration=B.knockback_duration,knockback_duration=B.knockback_duration,
  knockback_distance=B.knockback_distance,knockback_height=B.knockback_height,should_stun=1,
  center_x=p.x,center_y=p.y,center_z=p.z})
 if m then self.knockbacks=(self.knockbacks or 0)+1 end
end
