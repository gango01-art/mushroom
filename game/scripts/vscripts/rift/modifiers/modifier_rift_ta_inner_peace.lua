local B=require("rift.data.hero_balance").ta.inner_peace
local Core=require("rift.core.ta_meditation")
modifier_rift_ta_inner_peace = modifier_rift_ta_inner_peace or ((type(class) == "function") and class({}) or {})
function modifier_rift_ta_inner_peace:IsHidden()return self:GetStackCount()==0 end
function modifier_rift_ta_inner_peace:IsPurgable()return false end
function modifier_rift_ta_inner_peace:RemoveOnDeath()return false end
function modifier_rift_ta_inner_peace:GetTexture()return "templar_assassin_inner_peace"end
function modifier_rift_ta_inner_peace:Reset()
 self.last_damage=GameRules:GetGameTime();self:SetStackCount(0)
end
function modifier_rift_ta_inner_peace:OnCreated()
 if IsServer()then self:Reset();self:StartIntervalThink(B.interval)end
end
function modifier_rift_ta_inner_peace:OnIntervalThink()
 local c=self:GetParent()
 if not c:IsAlive()or c:PassivesDisabled()then self:SetStackCount(0);return end
 local fraction=Core.values(B,c:GetLevel(),GameRules:GetGameTime(),self.last_damage)
 self:SetStackCount(math.floor(fraction*100+.5))
end
function modifier_rift_ta_inner_peace:DeclareFunctions()
 return {MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
  MODIFIER_EVENT_ON_TAKEDAMAGE,MODIFIER_EVENT_ON_RESPAWN}
end
function modifier_rift_ta_inner_peace:OnTakeDamage(ev)
 if IsServer()and ev.unit==self:GetParent()and Core.interrupt(ev.damage)then self:Reset()end
end
function modifier_rift_ta_inner_peace:OnRespawn(ev)
 if IsServer()and ev.unit==self:GetParent()then self:Reset()end
end
function modifier_rift_ta_inner_peace:GetModifierConstantHealthRegen()
 local c=self:GetParent();if IsServer()and(not c:IsAlive()or c:PassivesDisabled())then return 0 end
 return (B.health_regen+B.health_per_level*math.max(0,c:GetLevel()-1))*self:GetStackCount()/100
end
function modifier_rift_ta_inner_peace:GetModifierConstantManaRegen()
 local c=self:GetParent();if IsServer()and(not c:IsAlive()or c:PassivesDisabled())then return 0 end
 return (B.mana_regen+B.mana_per_level*math.max(0,c:GetLevel()-1))*self:GetStackCount()/100
end
