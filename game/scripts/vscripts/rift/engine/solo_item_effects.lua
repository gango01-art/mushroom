local B=require("rift.data.solo_items")
local Core=require("rift.core.solo_items")
local Effects={}
function Effects.active(M)
 function M:IsPurgable()return true end
 function M:RemoveOnDeath()return true end
 function M:Values()local a=self:GetAbility();return a and not a:IsNull()and(B.items[a:GetAbilityName()]or{}).active or{}end
 function M:GetTexture()local a=self:GetAbility();return a and a:GetAbilityName()or"item_pipe"end
 function M:OnCreated()if IsServer()then self:SetStackCount(self:Values().barrier or 0)end end
 function M:OnRefresh()self:OnCreated()end
 function M:DeclareFunctions()return{MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,MODIFIER_EVENT_ON_ATTACK_LANDED}end
 function M:GetModifierMagicalResistanceBonus()return self:Values().magic_resistance or 0 end
 function M:GetModifierAttackSpeedBonus_Constant()return self:Values().attack_speed or 0 end
 function M:GetModifierMoveSpeedBonus_Percentage()return self:Values().move_speed_pct or 0 end
 function M:CheckState()return{[MODIFIER_STATE_NO_UNIT_COLLISION]=(self:Values().hit_damage or 0)>0}end
 function M:GetModifierTotal_ConstantBlock(ev)
  if not IsServer()or not ev or(ev.damage or 0)<=0 then return 0 end
  local d=self:Values()
  if d.attack_block and not ev.inflictor and ev.damage_type==DAMAGE_TYPE_PHYSICAL then return math.min(ev.damage,d.attack_block)end
  if not d.barrier then return 0 end
  local wanted=d.damage_type=="magical"and DAMAGE_TYPE_MAGICAL or DAMAGE_TYPE_PHYSICAL
  local blocked,left=Core.block(self:GetStackCount(),ev.damage,ev.damage_type,wanted)
  self:SetStackCount(left)
  -- The buff can also provide stats (Solar/Pipe), so an exhausted shield stays
  -- until its original expiry; zero pool never grants an extra free block.
  return blocked
 end
 function M:OnAttackLanded(ev)
  local c=self:GetParent();local d=self:Values()
  if not IsServer()or not d.hit_damage or ev.attacker~=c or ev.no_attack_cooldown or not ev.target or ev.target:IsNull()
   or ev.target:GetTeamNumber()==c:GetTeamNumber()or ev.target:IsBuilding()or ev.target:IsOther()then return end
  local a=self:GetAbility();self:Destroy()
  ApplyDamage({victim=ev.target,attacker=c,ability=a,damage=d.hit_damage,damage_type=DAMAGE_TYPE_PHYSICAL,
   damage_flags=DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION})
  if d.break_duration and ev.target:IsAlive()and not ev.target:IsDebuffImmune()then
   require("rift.engine.mods").add(ev.target,c,a,"modifier_rift_item_break",{duration=d.break_duration*(1-ev.target:GetStatusResistance())})
  end
 end
end
function Effects.lockout(L)
function L:IsHidden()return false end
function L:IsPurgable()return false end
function L:RemoveOnDeath()return false end
function L:GetTexture()return"item_mekansm"end
end
function Effects.aura(D)
function D:IsDebuff()return true end
function D:IsPurgable()return false end
function D:DeclareFunctions()return{MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}end
function D:GetModifierPhysicalArmorBonus()return B.items.item_assault.stats.enemy_armor end
end
function Effects.break_effect(K)
function K:IsDebuff()return true end
function K:IsPurgable()return true end
function K:GetTexture()return"item_silver_edge"end
function K:CheckState()return{[MODIFIER_STATE_PASSIVES_DISABLED]=true}end
end
return Effects
