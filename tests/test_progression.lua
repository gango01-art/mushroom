local B=require("rift.data.hero_balance")
local C=require("rift.core.progression")
local P=require("rift.engine.progression")
local Stub=require("engine_stub")
T.case("generated talents use the actual native attribute class, not generic Lua abilities",function()
 local f=assert(io.open("game/scripts/npc/npc_progression_abilities.txt","rb"));local s=f:read("*a");f:close()
 local count=0
 for name,body in s:gmatch('"(special_bonus_duality_[^"]+)"%s*(%b{})')do
  count=count+1;T.ok(body:find('"BaseClass" "special_bonus_base"',1,true),name)
  T.ok(body:find('"MaxLevel" "1"',1,true),name)
  T.ok(not body:find('"ScriptFile"',1,true),"Lua subclass cannot report IsAttributeBonus")
 end
 T.eq(count,176)
end)
T.case("native talent tiers and opposite-choice unlock levels are enforced",function()
 for tier,level in ipairs(B.progression.levels)do
  T.ok(not C.can_learn(B.progression,level-1,tier,false))
  T.ok(C.can_learn(B.progression,level,tier,false))
  local unlock=B.progression.opposite_levels[tier]
  T.ok(not C.can_learn(B.progression,unlock-1,tier,true))
  T.ok(C.can_learn(B.progression,unlock,tier,true))
 end
end)
for hero,paths in pairs(B.progression.heroes)do for path,d in pairs(paths)do
 T.case(hero.." "..path..": eight native talents, item flags independent, no shared state",function()
  T.eq(#d.talents,8)
  local none=C.total(d,{},false,false);T.eq(next(none),nil)
  local chosen={[1]=true,[4]=true,[5]=true,[8]=true}
  local sum=C.total(d,chosen,true,true)
  local expected={}
  for _,i in ipairs({1,4,5,8})do for k,v in pairs(d.talents[i])do expected[k]=(expected[k]or 0)+v end end
  for _,item in ipairs({"scepter","shard"})do for k,v in pairs(d[item])do expected[k]=(expected[k]or 0)+v end end
  for k,v in pairs(expected)do T.eq(sum[k],v)end
  sum.health=9999;T.eq(next(C.total(d,{},false,false)),nil)
 end)
end end
T.case("progression caps cooldown, area and extra volleys without modifying shared profiles",function()
 local cfg=B.progression
 T.eq(C.cooldown(40,{ult_cooldown_pct=100},cfg),30)
 T.eq(C.radius(100,{ult_radius=100},cfg),120)
 local base={radius=100,range=700,ticks=3,damage={100,200},attack={.5,1},duration={8,10}}
 local x=C.profile(base,{ult_radius=100,ult_cast_range=100,ult_ticks=10,ult_damage_pct=25,ult_duration=3},cfg)
 T.eq(x.radius,120);T.eq(x.range,800);T.eq(x.ticks,5);T.eq(x.damage[2],250);T.eq(x.attack[1],.625);T.eq(x.duration[1],11)
 T.eq(base.radius,100);T.eq(base.damage[2],200);T.eq(base.duration[1],8)
end)
local function setup(hero,path)
 local S=Stub.install();local u=S.hero(hero,0,2,Vector(0,0,0),{Damage=100});u.scepter=false
 u.mods.modifier_rift_progression={stacks=path=="physical"and 1 or 2}
 function u:HasScepter()return self.scepter or false end
 local function learn(i)
  local a=S.ability(1);u.abilities[P.name(hero,path,i)]=a
 end
 return S,u,learn
end
T.case("SF native-rank cooldown 40/35/30; talent, Scepter, Shard affect only current path",function()
 local S,u,learn=setup("npc_dota_hero_nevermore","physical")
 local a=S.lua_ability("sf_requiem_physical",u,3)
 T.eq(a:GetCooldown(-1),30)
 learn(6);T.eq(a:GetCooldown(-1),30)
 u.mods.modifier_rift_aghanim_state={stacks=5};u.mods.modifier_rift_aghanim_shard={}
 a:OnSpellStart();T.eq(u.mods.modifier_rift_sf_spheres.kv.duration,16)
 local m=S.lua_modifier("modifier_rift_sf_spheres",u,a)
 T.eq(m.session.cfg.duration,16);T.eq(m.session:regen_time(),1.5)
 T.eq(P.get(u,"sphere_damage_pct"),12)
 u.mods.modifier_rift_progression.stacks=2
 T.eq(P.get(u,"sphere_damage_pct"),0);T.eq(P.get(u,"ring_damage_bonus"),40)
 T.eq(a:GetCooldown(-1),30,"physical talent cannot leak after path state changes")
end)
T.case("magical SF native cooldown override targets Requiem only",function()
 local S,u,learn=setup("npc_dota_hero_nevermore","magical");learn(6)
 local m=S.lua_modifier("modifier_rift_progression",u,S.ability(1))
 local a={GetAbilityName=function()return"nevermore_requiem"end,GetLevelSpecialValueNoOverride=function()return 90 end}
 local params={ability=a,ability_special_value="AbilityCooldown",ability_special_level=2}
 T.eq(m:GetModifierOverrideAbilitySpecial(params),1);T.eq(m:GetModifierOverrideAbilitySpecialValue(params),81)
 params.ability_special_value="damage";T.eq(m:GetModifierOverrideAbilitySpecial(params),0)
end)
T.case("native talent OnUpgrade rejects opposite at 25 and refunds exactly one point",function()
 local S,u,learn=setup("npc_dota_hero_nevermore","physical");u.props.Level=25;u.props.AbilityPoints=2
 learn(1);require("rift.abilities.branch_talent")
 local name=P.name(u:GetUnitName(),"physical",2);local a=S.ability(1)
 function a:GetCaster()return u end
 function a:GetAbilityName()return name end
 function a:SetLevel(v)self.level=v end
 setmetatable(a,{__index=_G[name]});a:OnUpgrade()
 T.eq(a:GetHeroLevelRequiredToUpgrade(),27,"native UI must see the opposite talent as level-locked")
 T.eq(a:GetLevel(),0);T.eq(u:GetAbilityPoints(),3)
 u.props.Level=27;a.level=1;a:OnUpgrade();T.eq(a:GetLevel(),1);T.eq(u:GetAbilityPoints(),3)
end)
T.case("native ReplaceHeroWith talent copies do not unlearn or refund before spawn initialization",function()
 local S,u,learn=setup("npc_dota_hero_nevermore","physical");u.props.Level=1;u.props.AbilityPoints=0
 require("rift.abilities.branch_talent")
 local name=P.name(u:GetUnitName(),"physical",1);local a=S.ability(1)
 function a:GetCaster()return u end
 function a:GetAbilityName()return name end
 function a:SetLevel()error("must not unlearn during native construction")end
 setmetatable(a,{__index=_G[name]})
 GameRules.RiftArena={lab={loading=true}};a:OnUpgrade();T.eq(u:GetAbilityPoints(),0)
 GameRules.RiftArena=nil;u.mods.modifier_rift_progression=nil;a:OnUpgrade();T.eq(u:GetAbilityPoints(),0)
end)
T.case("TA crystal durability and magical shield use different item upgrades",function()
 local S,u=setup("npc_dota_hero_templar_assassin","physical");u.mods.modifier_rift_aghanim_state={stacks=5}
 local a=S.lua_ability("ta_psionic_crystal",u,3)
 local crystal=S.unit("npc_rift_ta_crystal",{team=4,pos=Vector(0,0,0)})
 local m=S.lua_modifier("modifier_rift_ta_crystal",crystal,a)
 T.eq(m.session.durability,4);T.eq(crystal:GetHealth(),4)
 T.eq(a:GetAOERadius(),520)
 u.mods.modifier_rift_progression.stacks=2;u.mods.modifier_rift_aghanim_shard={}
 local q=S.lua_ability("ta_refraction_magical",u,4)
 local shield=S.lua_modifier("modifier_rift_ta_refraction",u,q)
 T.eq(shield:GetStackCount(),B.ta.refraction_magical.instances[4]+2)
end)
T.case("Axe Scepter and talent area change the actual hit search and damage, removal restores range",function()
 local S,c,learn=setup("npc_dota_hero_axe","physical")
 c.props.Strength=0;c.props.Intellect=0;c.props.Agility=0;c.props.DisplayAttackSpeed=100
 local enemy=S.hero("enemy",1,3,Vector(500,0,0),{Health=1000,MaxHealth=1000})
 require("rift.abilities.path_ultimate")
 local a=S.ability(3)
 function a:GetCaster()return c end
 function a:GetAbilityName()return"rift_axe_physical"end
 setmetatable(a,{__index=rift_axe_physical})
 learn(5);c.mods.modifier_rift_aghanim_state={stacks=5};T.eq(a:GetAOERadius(),510)
 a:OnSpellStart();T.eq(#S.damage,1);T.eq(S.damage[1].victim,enemy);T.eq(S.damage[1].damage,454.25)
 c.mods.modifier_rift_aghanim_state=nil;T.eq(a:GetAOERadius(),465);a:OnSpellStart();T.eq(#S.damage,1)
end)
