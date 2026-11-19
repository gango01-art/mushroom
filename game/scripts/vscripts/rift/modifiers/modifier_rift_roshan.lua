local B=require("rift.core.config").roshan
modifier_rift_roshan = modifier_rift_roshan or ((type(class) == "function") and class({}) or {})
local M=modifier_rift_roshan
function M:IsHidden()return true end
function M:IsPurgable()return false end
function M:CheckState()
 local s=self:GetParent()._rift_roshan
 return {[MODIFIER_STATE_NO_UNIT_COLLISION]=s and s.travelling or false}
end
function M:DeclareFunctions()return {MODIFIER_EVENT_ON_TAKEDAMAGE}end
function M:OnCreated()if IsServer()then self:StartIntervalThink(B.think)end end
function M:OnTakeDamage(ev)
 if not IsServer()or ev.unit~=self:GetParent()or(ev.damage or 0)<=0 then return end
 local s=self:GetParent()._rift_roshan;if s then s.last_combat=s.gm:Now()end
end
function M:OnIntervalThink()
 local u=self:GetParent();local s=u._rift_roshan;if not s or not u:IsAlive()then return end
 local now=s.gm:Now();local home=s.pockets[s.index];local home_pos=GetGroundPosition(Vector(home.x,home.y,home.z),nil)
 if u:IsChanneling()then return end
 for _,name in ipairs(B.abilities)do
  local a=u:FindAbilityByName(name);if a and a:IsInAbilityPhase()then return end
 end
 if s.travelling then
  local toss=u:FindAbilityByName(B.throw_ability)
  -- Preserve the native grab/channel/throw animation before resuming the route.
  if u:IsChanneling()or(toss and toss:IsInAbilityPhase())then return end
  if toss and toss:IsFullyCastable()and(s.throw_count or 0)<B.max_throws_per_trip then
   for _,v in ipairs(FindUnitsInRadius(u:GetTeamNumber(),u:GetAbsOrigin(),nil,toss:GetCastRange(u:GetAbsOrigin(),nil),
    DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,FIND_CLOSEST,false))do
    if not v:IsInvulnerable()and not v:IsIllusion()then
     u:CastAbilityOnTarget(v,toss,-1);s.throw_count=(s.throw_count or 0)+1;return
    end
   end
  end
  u:MoveToPosition(s.destination);return
 end
 local origin=s.travelling and u:GetAbsOrigin()or home_pos
 local target
 for _,v in ipairs(FindUnitsInRadius(u:GetTeamNumber(),origin,nil,B.aggro,DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC,DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,FIND_CLOSEST,false))do
  if not v:IsInvulnerable()then target=v;break end
 end
 if target then
  if not s.travelling and(u:GetAbsOrigin()-home_pos):Length2D()>B.leash then u:MoveToPosition(home_pos);return end
  s.last_combat=now
  if u:GetAttackTarget()~=target then u:MoveToTargetToAttack(target)end
  local distance=(target:GetAbsOrigin()-u:GetAbsOrigin()):Length2D()
  local roar=u:FindAbilityByName(B.roar_ability)
  if roar and roar:IsFullyCastable()and u:GetHealth()/u:GetMaxHealth()<=B.roar_health_fraction and distance<=roar:GetSpecialValueFor("radius")then
   u:CastAbilityNoTarget(roar,-1);return
  end
  local slam=u:FindAbilityByName(B.slam_ability)
  if slam and slam:IsFullyCastable()and distance<=slam:GetSpecialValueFor("radius")then u:CastAbilityNoTarget(slam,-1);return end
 elseif s.travelling then u:MoveToPosition(s.destination)
 elseif(u:GetAbsOrigin()-home_pos):Length2D()>100 then u:MoveToPosition(home_pos)
 elseif u:GetAttackTarget()then u:Stop()end
end
