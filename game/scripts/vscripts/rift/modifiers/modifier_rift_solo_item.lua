local B=require("rift.data.solo_items")
local Core=require("rift.core.solo_items")
modifier_rift_solo_item = modifier_rift_solo_item or ((type(class) == "function") and class({}) or {})
local M=modifier_rift_solo_item
function M:IsHidden()return true end
function M:IsPurgable()return false end
function M:GetAttributes()return MODIFIER_ATTRIBUTE_MULTIPLE end
function M:Values()
 local c,a=self:GetParent(),self:GetAbility()
 if not a or a:IsNull()or c:IsIllusion()then return{}end
 if self:GetStackCount()~=1 then return{}end
 return B.items[a:GetAbilityName()].stats
end
function M:OnCreated()
 if IsServer()then self:OnIntervalThink();self:StartIntervalThink(.2)end
end
function M:OnIntervalThink()
 local c,a=self:GetParent(),self:GetAbility();if not a or a:IsNull()then return end
 local entries={}
 for slot=0,5 do local it=c:GetItemInSlot(slot);if it then entries[#entries+1]={name=it:GetAbilityName(),id=it:entindex()}end end
 local selected=Core.selected(entries,B.items)[a:entindex()]and 1 or 0
 if self:GetStackCount()~=selected then self:SetStackCount(selected);c:CalculateStatBonus(true)end
end
function M:DeclareFunctions()return{
 MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,MODIFIER_PROPERTY_STATS_AGILITY_BONUS,MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
 MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
 MODIFIER_PROPERTY_HEALTH_BONUS,MODIFIER_PROPERTY_MANA_BONUS,MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
 MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
 MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
 MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,MODIFIER_EVENT_ON_TAKEDAMAGE}end
function M:GetModifierBonusStats_Strength()local s=self:Values();return(s.all_stats or 0)+(s.strength or 0)end
function M:GetModifierBonusStats_Agility()return self:Values().all_stats or 0 end
function M:GetModifierBonusStats_Intellect()return self:Values().all_stats or 0 end
function M:GetModifierPreAttack_BonusDamage()return self:Values().attack_damage or 0 end
function M:GetModifierAttackSpeedBonus_Constant()return self:Values().attack_speed or 0 end
function M:GetModifierHealthBonus()return self:Values().health or 0 end
function M:GetModifierManaBonus()return self:Values().mana or 0 end
function M:GetModifierPhysicalArmorBonus()return self:Values().armor or 0 end
function M:GetModifierConstantHealthRegen()return self:Values().health_regen or 0 end
function M:GetModifierConstantManaRegen()return self:Values().mana_regen or 0 end
function M:GetModifierMagicalResistanceBonus()return self:Values().magic_resistance or 0 end
function M:GetModifierMoveSpeedBonus_Constant()return self:Values().move_speed or 0 end
function M:GetModifierMoveSpeedBonus_Special_Boots()return self:Values().boots_speed or 0 end
function M:GetModifierTotal_ConstantBlock(ev)
 if not IsServer()or not ev or ev.inflictor or ev.damage_type~=DAMAGE_TYPE_PHYSICAL then return 0 end
 local s=self:Values()
 -- Crimson's stronger active replaces its passive block; never both.
 if not s.attack_block or self:GetParent():HasModifier("modifier_rift_item_crimson_guard")then return 0 end
 return RandomInt(1,100)<=(s.block_chance or 0)and math.min(ev.damage,s.attack_block)or 0
end
function M:OnTakeDamage(ev)
 if not IsServer()or ev.attacker~=self:GetParent()or ev.inflictor or ev.damage<=0 or not ev.unit or ev.unit:IsNull()
  or ev.unit:GetTeamNumber()==self:GetParent():GetTeamNumber()or ev.unit:IsBuilding()or ev.unit:IsOther()then return end
 local ls=self:Values().lifesteal or 0
 if not ev.unit:IsRealHero()or ev.unit:IsIllusion()then ls=ls*B.lifesteal_creep_fraction end
 if ls>0 then self:GetParent():Heal(ev.damage*ls/100,self:GetAbility())end
end
function M:IsAura()return(self:Values().enemy_armor or 0)<0 end
function M:GetAuraRadius()return self:Values().enemy_radius or 0 end
function M:GetAuraSearchTeam()return DOTA_UNIT_TARGET_TEAM_ENEMY end
function M:GetAuraSearchType()return DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC end
function M:GetAuraSearchFlags()return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES end
function M:GetModifierAura()return "modifier_rift_item_assault_debuff"end
