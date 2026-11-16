modifier_rift_sven_echo = modifier_rift_sven_echo or ((type(class) == "function") and class({}) or {})
function modifier_rift_sven_echo:IsHidden() return true end
function modifier_rift_sven_echo:IsPurgable() return false end
function modifier_rift_sven_echo:DeclareFunctions() return {MODIFIER_EVENT_ON_ATTACK_LANDED} end
function modifier_rift_sven_echo:OnAttackLanded(ev)
  if not IsServer() then return end
  local c,a,u=self:GetParent(),self:GetAbility(),ev.target
  if ev.attacker~=c or c:IsIllusion() or c:PassivesDisabled() or self.echoing or not a or a:IsNull()
    or a:GetLevel()<1 or a:GetCooldownTimeRemaining()>0 or not u or u:IsNull() or not u:IsAlive()
    or u:GetTeamNumber()==c:GetTeamNumber() or u:IsBuilding() or u:IsOther() then return end
  a:StartCooldown(require("rift.data.hero_balance").passives.sven_echo_cooldown[a:GetLevel()])
  c:SetContextThink("rift_sven_echo",function()
    if c:IsNull() or not c:IsAlive() or c:PassivesDisabled() or c:IsStunned() or c:IsDisarmed()
      or u:IsNull() or not u:IsAlive() or u:IsInvulnerable()
      or (u:GetAbsOrigin()-c:GetAbsOrigin()):Length2D()>c:Script_GetAttackRange()+100 then return nil end
    self.echoing=true
    -- The first hit has already landed. Restart its follow-through as a fast
    -- second swing, rather than stacking the same gesture over itself.
    local Log=require("rift.engine.log")
    Log.try(c,"Sven echo","FadeGesture",ACT_DOTA_ATTACK)
    Log.try(c,"Sven echo","StartGestureWithPlaybackRate",ACT_DOTA_ATTACK,require("rift.data.hero_balance").passives.sven_echo_gesture_rate)
    c:PerformAttack(u,true,true,true,true,false,false,false)
    self.echoing=false
    return nil
  end,0.12)
end
