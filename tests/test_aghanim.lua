local Stub=require("engine_stub")
local A=require("rift.engine.aghanim")
local B=require("rift.data.hero_balance").progression
T.case("DUALITY ownership: inventory, backpack, Blessing and whitelisted hybrid Shards",function()
 for hero in pairs(B.heroes)do
  local S=Stub.install();local c=S.hero(hero,0,2,Vector(0,0,0),{})
  function c:CalculateStatBonus()end
  local m=S.lua_modifier("modifier_rift_aghanim_state",c,S.ability(1));c.mods.modifier_rift_aghanim_state=m
  local item=S.ability(1);function item:GetAbilityName()return"item_ultimate_scepter"end
  c.inventory[0]=item;c.inventory[1]=item;m:OnIntervalThink()
  T.ok(A.scepter(c));T.eq(m:GetModifierBonusStats_Strength(),10);T.eq(m:GetModifierHealthBonus(),175)
  c.inventory[0]=nil;c.inventory[1]=nil;c.inventory[6]=item;m:OnIntervalThink()
  T.ok(not A.scepter(c));T.eq(m:GetModifierManaBonus(),0)
  c.mods.modifier_rift_aghanim_blessing={};c.mods.modifier_rift_aghanim_shard={};m:OnIntervalThink()
  T.ok(A.scepter(c));T.ok(A.shard(c));T.eq(m:GetModifierBonusStats_Agility(),0)
  T.eq(c:HasModifier("modifier_item_aghanims_shard"),B.hybrid_shards[hero]~=nil)
  if B.hybrid_shards[hero]then T.eq(next(B.heroes[hero].physical.shard),nil);T.eq(next(B.heroes[hero].magical.shard),nil)end
  c.inventory[0]=item;m:OnIntervalThink()
  IsServer=function()return false end;function c:GetItemInSlot()error("client inventory API")end
  T.eq(m:GetModifierBonusStats_Intellect(),10)
 end
end)
T.case("consumables ignore stash, consume from backpack and preserve duplicate purchases",function()
 for _,name in ipairs({"item_aghanims_shard","item_ultimate_scepter_2"})do
  local S=Stub.install();local c=S.hero("npc_dota_hero_templar_assassin",0,2,Vector(0,0,0),{})
  function c:CalculateStatBonus()end
  local m=S.lua_modifier("modifier_rift_aghanim_state",c,S.ability(1));c.mods.modifier_rift_aghanim_state=m
  local item=S.ability(1);function item:GetAbilityName()return name end
  function c:RemoveItem(a)self.consumed=a end
  local intrinsic=S.lua_modifier("modifier_rift_aghanim_item",c,item)
  c.inventory[9]=item;intrinsic:OnIntervalThink();T.eq(rawget(c,"consumed"),nil)
  c.inventory[9]=nil;c.inventory[6]=item;intrinsic:OnIntervalThink();T.eq(c.consumed,item)
  T.ok(name=="item_aghanims_shard"and A.shard(c)or A.scepter(c))
  c.consumed=nil;intrinsic:OnIntervalThink();T.eq(rawget(c,"consumed"),nil)
 end
end)

