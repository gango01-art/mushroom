local Stub=require("engine_stub")
local B=require("rift.data.hero_balance")
T.case("guarded native API failure returns nil rather than an arithmetic-unsafe error string",function()
 local Log=require("rift.engine.log")
 T.eq(Log.try({call=function()error("native signature changed")end},"test","call"),nil)
end)
T.case("Lina solar waves use displayed attack speed without treating it as attack damage",function()
 local d=require("rift.data.expansion").abilities.rift_lina_physical
 local Math=require("rift.core.path_math")
 T.eq(Math.damage(d,3,{attack=200,attack_speed=100}),115)
 T.eq(Math.damage(d,3,{attack=200,attack_speed=200}),150)
end)
T.case("LC courage counts outgoing hits, excludes its own counterattack and heals only its damage",function()
 local S=Stub.install();local c=S.hero("lc",0,2,Vector(0,0,0),{Health=500,MaxHealth=2000})
 local u=S.hero("enemy",1,3,Vector(100,0,0),{})
 local a=S.lua_ability("rift_lc_courage",c,4)
 local m=S.lua_modifier("modifier_rift_lc_courage",c,a)
 m:OnAttackLanded({attacker=u,target=c});T.eq(m.hits,0)
 for _=1,4 do m:OnAttackLanded({attacker=c,target=u}) end
 local perform=c.PerformAttack
 function c:PerformAttack(target,...)
  perform(self,target,...);m:OnAttackLanded({attacker=self,target=target})
  m:OnTakeDamage({attacker=self,unit=target,damage=100})
 end
 S.advance(.1);T.eq(#S.attacks,1);T.eq(m.hits,0);T.eq(c:GetHealth(),540)
 m:OnTakeDamage({attacker=c,unit=u,damage=100});T.eq(c:GetHealth(),540)
end)
T.case("Axe physical changes native counter requirements and enables outgoing attacks",function()
 local S=Stub.install();local c=S.hero("axe",0,2,Vector(0,0,0),{})
 local a=S.ability(4);function a:GetAbilityName()return "axe_counter_helix" end
 local m=S.lua_modifier("modifier_rift_axe_helix",c,a)
 for i=0,3 do
  T.eq(m:GetModifierOverrideAbilitySpecialValue({ability=a,ability_special_value="trigger_attacks",ability_special_level=i}),8-i)
 end
 T.eq(m:GetModifierOverrideAbilitySpecialValue({ability=a,ability_special_value="attacks_increase_counter"}),1)
 T.eq(m:GetModifierOverrideAbilitySpecial({ability=a,ability_special_value="damage"}),0)
end)
T.case("LC buff tooltips expose actual fractional damage and spell amplification",function()
 local S=Stub.install();local c=S.hero("lc",0,2,Vector(0,0,0),{})
 local a=S.ability(2);c.abilities.lc_duel_magical=a
 local p=S.lua_modifier("modifier_rift_lc_duel_damage",c,a);p:SetStackCount(14);T.eq(p:OnTooltip(),1.4)
 local m=S.lua_modifier("modifier_rift_lc_spell_amp",c,a);m:SetStackCount(125)
 T.eq(m:OnTooltip(),12.5);T.eq(m:OnTooltip2(),7.5)
end)
T.case("current-rank getters handle the engine sentinel on original custom ultimates",function()
  local S=Stub.install();local c=S.hero("caster",0,2,Vector(0,0,0),{})
  local cases={pa_phantom_execution={24,20,16},lc_duel_physical={85,75,65},sf_requiem_physical={80,70,60},ta_psionic_crystal={10,9,8},ta_psionic_blast={14,12,10}}
  for name,cd in pairs(cases) do for rank=1,3 do
    local a=S.lua_ability(name,c,rank);T.eq(a:GetCooldown(-1),cd[rank]);T.eq(a:GetCooldown(rank-1),cd[rank])
  end end
end)
for rank=1,4 do
  T.case("Sven E echo rank "..rank.." attacks once and cannot recurse",function()
    local S=Stub.install()
    local c=S.hero("sven",0,2,Vector(0,0,0),{})
    local u=S.hero("enemy",1,3,Vector(100,0,0),{})
    local a=S.lua_ability("rift_sven_echo",c,rank)
    local m=S.lua_modifier("modifier_rift_sven_echo",c,a)
    local perform=c.PerformAttack
    function c:PerformAttack(target,...) perform(self,target,...);m:OnAttackLanded({attacker=self,target=target}) end
    m:OnAttackLanded({attacker=c,target=u});S.advance(.2)
    T.eq(#S.attacks,1);T.eq(a:GetCooldown(rank-1),B.passives.sven_echo_cooldown[rank])
    m:OnAttackLanded({attacker=c,target=u});S.advance(.2);T.eq(#S.attacks,1)
  end)
  T.case("Sven E mystic rank "..rank.." radius and debuff values disable under Break",function()
    local S=Stub.install();local c=S.hero("sven",0,2,Vector(0,0,0),{})
    local a=S.lua_ability("rift_sven_mystic_cleave",c,rank)
    local m=S.lua_modifier("modifier_rift_sven_mystic",c,a)
    T.eq(m:GetModifierAoEBonusConstantStacking(),B.passives.sven_radius[rank])
    T.eq(m:GetModifierStatusResistanceCaster(),4*rank)
    T.eq(require("rift.engine.area").radius(c,350),350+B.passives.sven_radius[rank])
    c.broken=true;T.eq(m:GetModifierStatusResistanceCaster(),0);T.eq(require("rift.engine.area").radius(c,350),350)
  end)
  T.case("Juggernaut E magic crit rank "..rank.." mutates one spell or item event once",function()
    local S=Stub.install();local c=S.hero("jug",0,2,Vector(0,0,0),{})
    S.lua_ability("rift_juggernaut_spell_crit",c,rank)
    _G.bit={band=function(a,b)return a==b and a or 0 end}
    _G.RandomInt=function()return 40 end
    local source=S.ability(1);function source:GetAbilityName()return "test_spell" end;S.by_index[999]=source
    local ev={damage=100,damagetype_const=DAMAGE_TYPE_MAGICAL,entindex_inflictor_const=999,entindex_attacker_const=c:entindex()}
    local Crit=require("rift.engine.spell_crit")
    Crit.filter(ev);T.eq(ev.damage,B.passives.jug_multiplier[rank]);T.eq(#S.damage,0)
    ev.damage=100;_G.RandomInt=function()return 41 end;Crit.filter(ev);T.eq(ev.damage,100)
    _G.RandomInt=function()return 1 end;ev.damage_flags=DOTA_DAMAGE_FLAG_REFLECTION;Crit.filter(ev);T.eq(ev.damage,100)
    ev.damage_flags=0;c.broken=true;Crit.filter(ev);T.eq(ev.damage,100)
  end)
end
T.case("PA many-target daggers deduplicate, isolate invalid targets and roll once",function()
  local Storm=require("rift.core.pa_storm_daggers")
  local s=Storm.new(4);s.force_proc=true
  local id=s:begin_many(1,{2,3,4,4,5},{chain_chance=1,chain_damage=460,cast_context_seconds=3},0)
  T.eq(s:on_hit(id,2,true,1),nil);T.eq(s:on_hit(id,2,true,1),nil)
  T.eq(s:on_hit(id,3,false,1),nil);T.eq(s:on_hit(id,4,true,1),nil)
  local result=s:on_hit(id,5,true,1)
  T.eq(#result.targets,3);T.eq(result.targets[1],2);T.eq(result.targets[2],4);T.eq(result.targets[3],5)
  T.eq(s:on_hit(id,5,true,1),nil);T.eq(s:count(),0)
end)
