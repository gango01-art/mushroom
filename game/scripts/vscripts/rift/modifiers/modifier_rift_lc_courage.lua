local B=require("rift.data.hero_balance").lc.courage_physical
modifier_rift_lc_courage = modifier_rift_lc_courage or ((type(class) == "function") and class({}) or {})
function modifier_rift_lc_courage:IsHidden() return false end
function modifier_rift_lc_courage:IsPurgable() return false end
function modifier_rift_lc_courage:OnCreated() if IsServer() then self.hits=0 end end
function modifier_rift_lc_courage:GetTexture() return "legion_commander_moment_of_courage" end
function modifier_rift_lc_courage:DeclareFunctions() return {MODIFIER_EVENT_ON_ATTACK_LANDED,MODIFIER_EVENT_ON_TAKEDAMAGE} end
function modifier_rift_lc_courage:OnTakeDamage(ev)
 if IsServer() and self.countering and ev.attacker==self:GetParent() and ev.unit==self.counter_target and not ev.inflictor then
  self:GetParent():Heal(ev.damage*B.lifesteal[self:GetAbility():GetLevel()]/100,self:GetAbility())
  require("rift.engine.log").debug("LC","counterattack damage="..ev.damage.." lifesteal="..B.lifesteal[self:GetAbility():GetLevel()])
 end
end
function modifier_rift_lc_courage:OnAttackLanded(ev)
 if not IsServer() then return end
 local c,a,u=self:GetParent(),self:GetAbility(),ev.target
 if ev.attacker~=c or self.countering or c:IsIllusion() or c:PassivesDisabled() or not u or u:IsNull()
  or u:GetTeamNumber()==c:GetTeamNumber() or u:IsBuilding() or u:IsOther() or a:GetLevel()<1 then return end
 self.hits=math.min(B.attacks[a:GetLevel()],self.hits+1);self:SetStackCount(self.hits)
 if self.hits<B.attacks[a:GetLevel()] or a:GetCooldownTimeRemaining()>0 then return end
 self.hits=0;self:SetStackCount(0);a:StartCooldown(B.cooldown)
 c:SetContextThink("rift_lc_courage",function()
  if c:IsNull() or not c:IsAlive() or c:PassivesDisabled() or c:IsDisarmed() or c:IsStunned()
   or u:IsNull() or not u:IsAlive() or (u:GetAbsOrigin()-c:GetAbsOrigin()):Length2D()>c:Script_GetAttackRange()+100 then return nil end
  self.countering=true;self.counter_target=u
  c:StartGesture(ACT_DOTA_ATTACK)
  c:PerformAttack(u,true,true,true,true,false,false,false)
  self.countering=false;self.counter_target=nil
  EmitSoundOn("Hero_LegionCommander.Courage",c)
  return nil
 end,.03)
end
