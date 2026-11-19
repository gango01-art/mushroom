-- Keep the real Necromastery modifier: native attack damage, soul cap, Frenzy
-- and Requiem read that same pool. Override only kill gain/death retention.
local B=require("rift.data.hero_balance").sf.souls
modifier_rift_sf_soul_gain = modifier_rift_sf_soul_gain or ((type(class) == "function") and class({}) or {})
function modifier_rift_sf_soul_gain:IsHidden() return true end
function modifier_rift_sf_soul_gain:IsPurgable() return false end
function modifier_rift_sf_soul_gain:RemoveOnDeath() return false end
function modifier_rift_sf_soul_gain:OnCreated()
 if IsServer() then
  self.raze_casts={};self.claimed={}
  local native=self:GetParent():FindModifierByName("modifier_nevermore_necromastery")
  if native then native:ForceRefresh() end
  local c=self:GetParent();local alive=c:IsAlive()
  GameRules:GetGameModeEntity():SetContextThink("rift_sf_life_"..c:entindex(),function()
   if c:IsNull() or not c:HasModifier("modifier_rift_sf_soul_gain") then return nil end
   local current=c:IsAlive()
   if alive and not current then require("rift.engine.sf_souls").on_death(c) end
   alive=current;return .1
  end,.1)
 end
end
function modifier_rift_sf_soul_gain:DeclareFunctions()
 return {MODIFIER_EVENT_ON_ATTACK_LANDED,MODIFIER_EVENT_ON_ABILITY_EXECUTED,MODIFIER_EVENT_ON_TAKEDAMAGE,MODIFIER_EVENT_ON_DEATH,
  MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE}
end
local function override(ev)
 if not ev.ability or ev.ability:IsNull() or ev.ability:GetAbilityName()~="nevermore_necromastery" then return nil end
 local key=ev.ability_special_value
 if key=="souls_per_kill" or key=="souls_per_hero_kill" or key=="shard_souls_per_kill" then return 0 end
 if key=="necromastery_soul_release" then return 1 end
 if key=="soul_release_tooltip" then return B.death_loss*100 end
end
function modifier_rift_sf_soul_gain:GetModifierOverrideAbilitySpecial(ev) return override(ev)~=nil and 1 or 0 end
function modifier_rift_sf_soul_gain:GetModifierOverrideAbilitySpecialValue(ev) return override(ev) or 0 end
local function valid_target(c,u)
 return u and not u:IsNull() and u:GetTeamNumber()~=c:GetTeamNumber() and not u:IsBuilding() and not u:IsOther()
end
local function raze(a) return a and not a:IsNull() and a:GetAbilityName():find("nevermore_shadowraze",1,true)==1 end
function modifier_rift_sf_soul_gain:AddSouls(count)
 local c=self:GetParent()
 if c:IsIllusion() or c:PassivesDisabled() or not c:IsAlive() then return end
 local a=c:FindAbilityByName("nevermore_necromastery")
 local m=c:FindModifierByName("modifier_nevermore_necromastery")
 if not a or a:GetLevel()<1 or not m then return end
 local cap=a:GetSpecialValueFor("current_max_souls_tooltip")
 if cap<=0 then cap=a:GetSpecialValueFor("necromastery_max_souls") end
 local current=m:GetStackCount()
 -- Never remove temporary Frenzy souls when the ordinary pool is already full.
 m:SetStackCount(math.min(current+count,math.max(current,cap)))
end
function modifier_rift_sf_soul_gain:OnAttackLanded(ev)
 if IsServer() and ev.attacker==self:GetParent() and valid_target(ev.attacker,ev.target) then self:AddSouls(B.per_attack) end
end
function modifier_rift_sf_soul_gain:OnAbilityExecuted(ev)
 if not IsServer() or ev.unit~=self:GetParent() or not raze(ev.ability) then return end
 local key=ev.ability:GetAbilityName()
 self.raze_casts[key]=(self.raze_casts[key] or 0)+1;self.claimed[key]=nil
end
function modifier_rift_sf_soul_gain:OnTakeDamage(ev)
 if not IsServer() or ev.attacker~=self:GetParent() or not raze(ev.inflictor) or not valid_target(ev.attacker,ev.unit) then return end
 local key=ev.inflictor:GetAbilityName()
 local cast=self.raze_casts[key] or 0
 if self.claimed[key]==cast then return end
 self.claimed[key]=cast;self:AddSouls(B.per_raze)
end
function modifier_rift_sf_soul_gain:OnDeath(ev)
 if not IsServer() or ev.unit~=self:GetParent() or ev.reincarnate==true or ev.reincarnate==1 then return end
 require("rift.engine.sf_souls").on_death(self:GetParent())
end
