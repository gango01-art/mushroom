local B=require("rift.data.solo_items")
local C=require("rift.core.solo_items")
local Stub=require("engine_stub")
T.case("native item tooltip rows replace inherited stats and reserve the active title for mana/CD",function()
 local function read(p)local f=assert(io.open(p,"rb"));local s=f:read("*a");f:close();return s end
 local kv=read("game/scripts/npc/npc_items_custom.txt")
 local loc=read("game/resource/addon_russian.txt")
 for name,d in pairs(B.items)do
  local block=assert(kv:match('"'..name..'"%s*(%b{})'))
  T.ok(block:find('"AbilityCastRange" "0"',1,true),name.." must clear inherited cast range")
  T.ok(block:find('"AbilityUnitTargetTeam" "DOTA_UNIT_TARGET_TEAM_NONE"',1,true),name.." self-only target metadata")
  for key,value in pairs(d.stats)do T.ok(block:find('"solo_stat_'..key..'" "'..value..'"',1,true),name.." stat "..key)end
  local desc=assert(loc:match('"DOTA_Tooltip_ability_'..name..'_Description"%s*"([^"\n]*)"'))
  T.ok(desc:find("<h1>",1,true),name.." native title")
  T.ok(not desc:find("Пассивно владельцу:",1,true),name.." old dense paragraph")
  T.ok(not desc:find("solo_active_mana",1,true),name.." mana cost belongs in native title")
 end
 local boots=assert(kv:match('"item_boots_of_bearing"%s*(%b{})'))
 T.ok(boots:find('"bonus_health_regen" "0"',1,true),"old 18 regen must not remain visible")
 T.ok(boots:find('"solo_stat_health_regen" "14"',1,true))
 T.ok(loc:find('"DOTA_Tooltip_ability_item_glimmer_cape" "Glimmer Cape"',1,true))
 T.ok(loc:find('"DOTA_Tooltip_ability_item_boots_of_bearing" "Boots of Bearing"',1,true))
end)
T.case("upgrade families select one strongest active-slot item and handle duplicate crowns recipes",function()
 local selected=C.selected({{name="item_pavise",id=1},{name="item_solar_crest",id=2},{name="item_solar_crest",id=3},
  {name="item_invis_sword",id=4},{name="item_silver_edge",id=5}},B.items)
 T.eq(selected[1],nil);T.eq(selected[2],true);T.eq(selected[3],nil);T.eq(selected[4],nil);T.eq(selected[5],true)
 for _,name in ipairs({"item_recipe_glimmer_cape","item_recipe_invis_sword"})do
  local crowns=0;for _,c in ipairs(B.recipes[name].components)do T.ok(c~="item_shadow_amulet");if c=="item_crown"then crowns=crowns+1 end end
  T.eq(crowns,2)
 end
 T.eq(B.items.item_glimmer_cape.stats.all_stats,10);T.eq(B.items.item_invis_sword.stats.all_stats,10);T.eq(B.items.item_silver_edge.stats.all_stats,10)
end)
T.case("Glimmer has the owner's ten percent active MR and cannot replace Pipe's magic protection",function()
 local g,p=B.items.item_glimmer_cape,B.items.item_pipe
 T.eq(g.active.magic_resistance,10);T.eq(g.active.barrier,nil);T.ok(p.cost>g.cost)
 local gm=(1-g.stats.magic_resistance/100)*(1-g.active.magic_resistance/100)
 local pm=(1-p.stats.magic_resistance/100)*(1-p.active.magic_resistance/100)
 T.ok(pm<gm);T.ok(p.active.barrier>=400)
end)
T.case("barrier depletion is exact and ignores the other damage type",function()
 local blocked,left=C.block(250,300,"physical","physical");T.eq(blocked,250);T.eq(left,0)
 blocked,left=C.block(left,100,"physical","physical");T.eq(blocked,0);T.eq(left,0)
 blocked,left=C.block(250,300,"magical","physical");T.eq(blocked,0);T.eq(left,250)
end)
T.case("Greaves healing is bounded on strength-stacking heroes",function()
 T.eq(C.heal(B.items.item_guardian_greaves.active,2000),470)
 T.eq(C.heal(B.items.item_guardian_greaves.active,20000),600)
 T.eq(C.heal(B.items.item_mekansm.active,20000),275)
end)
local function setup(name,modifier)
 local S=Stub.install();local c=S.hero("hero",0,2,Vector(0,0,0),{Health=1000,MaxHealth=2000})
 DAMAGE_TYPE_PHYSICAL=1;DAMAGE_TYPE_MAGICAL=2;DAMAGE_TYPE_PURE=4
 function c:CalculateStatBonus()end
 local a=S.ability(1);function a:GetAbilityName()return name end;function a:entindex()return 999 end;c.inventory[0]=a
 return S,c,a,S.lua_modifier(modifier or"modifier_rift_solo_item",c,a)
end
T.case("item stats are replicated without calling server-only inventory APIs on the client",function()
 local S,c,a,m=setup("item_glimmer_cape")
 T.eq(m:GetModifierBonusStats_Strength(),10);T.eq(m:GetModifierMagicalResistanceBonus(),18)
 IsServer=function()return false end
 function c:GetItemInSlot()error("client inventory API forbidden")end
 T.eq(m:GetModifierBonusStats_Agility(),10);T.eq(m:GetModifierBonusStats_Intellect(),10)
end)
T.case("Pipe blocks magical damage only and does not replenish an exhausted pool",function()
 local S,c,a,m=setup("item_pipe","modifier_rift_item_pipe")
 T.eq(m:GetModifierTotal_ConstantBlock({damage=200,damage_type=DAMAGE_TYPE_PHYSICAL}),0)
 T.eq(m:GetStackCount(),450)
 T.eq(m:GetModifierTotal_ConstantBlock({damage=300,damage_type=DAMAGE_TYPE_MAGICAL}),300)
 T.eq(m:GetModifierTotal_ConstantBlock({damage=300,damage_type=DAMAGE_TYPE_MAGICAL}),150)
 T.eq(m:GetModifierTotal_ConstantBlock({damage=300,damage_type=DAMAGE_TYPE_MAGICAL}),0)
 T.eq(m:GetModifierMagicalResistanceBonus(),15)
end)
T.case("Crimson's active replaces passive attack block and does not block physical spells",function()
 local S,c,a,m=setup("item_crimson_guard")
 RandomInt=function()return 1 end
 T.eq(m:GetModifierTotal_ConstantBlock({damage=100,damage_type=DAMAGE_TYPE_PHYSICAL}),40)
 c.mods.modifier_rift_item_crimson_guard={}
 T.eq(m:GetModifierTotal_ConstantBlock({damage=100,damage_type=DAMAGE_TYPE_PHYSICAL}),0)
 local active=S.lua_modifier("modifier_rift_item_crimson_guard",c,a)
 T.eq(active:GetModifierTotal_ConstantBlock({damage=100,damage_type=DAMAGE_TYPE_PHYSICAL}),70)
 T.eq(active:GetModifierTotal_ConstantBlock({damage=100,damage_type=DAMAGE_TYPE_PHYSICAL,inflictor={}}),0)
end)
T.case("Shadow Blade has phased movement with no invisibility state; spell extra attacks do not consume it",function()
 local S,c,a,m=setup("item_invis_sword","modifier_rift_item_shadow_weapon")
 MODIFIER_STATE_NO_UNIT_COLLISION=9991;MODIFIER_STATE_INVISIBLE=9992
 local state=m:CheckState();T.eq(state[MODIFIER_STATE_NO_UNIT_COLLISION],true);T.eq(state[MODIFIER_STATE_INVISIBLE],nil)
 local u=S.hero("enemy",1,3,Vector(100,0,0),{})
 m:OnAttackLanded({attacker=c,target=u,no_attack_cooldown=true});T.eq(#S.damage,0)
 m:OnAttackLanded({attacker=c,target=u});T.eq(#S.damage,1);T.eq(S.damage[1].damage,120)
end)
