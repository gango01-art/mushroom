local B=require("rift.core.config").river_camps
modifier_rift_river_neutral = modifier_rift_river_neutral or ((type(class) == "function") and class({}) or {})
local M=modifier_rift_river_neutral
function M:IsHidden()return true end
function M:IsPurgable()return false end
function M:OnCreated()if IsServer()then self:StartIntervalThink(B.think)end end
function M:OnIntervalThink()
 local u=self:GetParent();local data=u._rift_river;if not data or not u:IsAlive()then return end
 local home=data.origin
 if (u:GetAbsOrigin()-home):Length2D()>B.leash then
  u:MoveToPosition(home);u:Heal(u:GetMaxHealth()*B.heal_pct/100,nil);return
 end
 local target
 for _,v in ipairs(FindUnitsInRadius(u:GetTeamNumber(),home,nil,B.aggro,DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC,DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,FIND_CLOSEST,false))do
  if not v:IsInvulnerable()then target=v;break end
 end
 if target then if u:GetAttackTarget()~=target then u:MoveToTargetToAttack(target)end
 elseif (u:GetAbsOrigin()-home):Length2D()>110 then u:MoveToPosition(home)
 elseif u:GetAttackTarget()then u:Stop()end
end
