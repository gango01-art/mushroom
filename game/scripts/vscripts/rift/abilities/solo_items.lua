local B=require("rift.data.solo_items")
local Core=require("rift.core.solo_items")
local Mods=require("rift.engine.mods")
for name,def in pairs(B.items)do
 local A=(type(class)=="function")and class({})or{}
 _G[name]=A
 function A:GetIntrinsicModifierName()return "modifier_rift_solo_item"end
 function A:CastFilterResult()
  if self:GetCaster():IsIllusion()then return UF_FAIL_CUSTOM end
  if def.active and def.active.heal_lockout and self:GetCaster():HasModifier("modifier_rift_item_recovery_lockout")then return UF_FAIL_CUSTOM end
  return UF_SUCCESS
 end
 function A:GetCustomCastError()return "#rift_item_recovery_error"end
 function A:OnSpellStart()
  local c=self:GetCaster();local d=def.active
  if not d or c:IsIllusion()then return end
  if d.heal_lockout and c:HasModifier("modifier_rift_item_recovery_lockout")then return end
  if d.purge then c:Purge(false,true,false,false,false)end
  if d.heal then c:Heal(Core.heal(d,c:GetMaxHealth()),self)end
  if d.restore_mana then c:GiveMana(d.restore_mana)end
  if d.heal_lockout then Mods.add(c,c,self,"modifier_rift_item_recovery_lockout",{duration=d.heal_lockout})end
  if d.duration then Mods.add(c,c,self,"modifier_".."rift_item_"..def.family,{duration=d.duration})end
  local fx=d.hit_damage and "particles/items_fx/phase_boots.vpcf" or "particles/items3_fx/lotus_orb_shield.vpcf"
  local p=ParticleManager:CreateParticle(fx,PATTACH_ABSORIGIN_FOLLOW,c)
  GameRules:GetGameModeEntity():SetContextThink("rift_solo_fx_"..p,function()
   ParticleManager:DestroyParticle(p,false);ParticleManager:ReleaseParticleIndex(p)
  end,.8)
 end
end

-- Removed from the shop; even a dev-created amulet has no invisibility cast.
item_shadow_amulet = item_shadow_amulet or ((type(class) == "function") and class({}) or {})
