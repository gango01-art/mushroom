local Stub=require("engine_stub")
local B=require("rift.data.hero_balance")
T.case("CM physical gains one damage per point of snapshotted mana regeneration",function()
 local d=require("rift.data.expansion").abilities.rift_cm_physical
 local Math=require("rift.core.path_math")
 T.eq(Math.damage(d,3,{attack=200,mana_regen=25})-Math.damage(d,3,{attack=200,mana_regen=0}),25)
end)
T.case("Juggernaut series records keep rank CDR while ordinary attacks only give 0.1",function()
 local S=Stub.install();local c=S.hero("jug",0,2,Vector(0,0,0),{})
 local u=S.hero("enemy",1,3,Vector(100,0,0),{})
 local a=S.ability(3);function a:GetAbilityName()return "rift_juggernaut_physical" end
 local m=S.lua_modifier("modifier_rift_attack_cooldowns",c,a)
 a:StartCooldown(10);m:OnAttackLanded({attacker=c,target=u});T.eq(a:GetCooldownTimeRemaining(),9.9)
 c._rift_sleight_attack=true;m:OnAttackRecord({attacker=c,record=77});c._rift_sleight_attack=nil
 m:OnAttackLanded({attacker=c,target=u,record=77,no_attack_cooldown=true});T.eq(a:GetCooldownTimeRemaining(),7.9)
 m:OnAttackRecordDestroy({record=77});T.eq(m.sleight_records[77],nil)
 m:OnAttackLanded({attacker=c,target=u,record=78,no_attack_cooldown=true});T.eq(a:GetCooldownTimeRemaining(),7.9)
end)
T.case("PA physical has one second CDR for ordinary attacks and retains dagger rank CDR without double counting",function()
 local S=Stub.install();local c=S.hero("pa",0,2,Vector(0,0,0),{})
 local u=S.hero("enemy",1,3,Vector(100,0,0),{})
 local a=S.lua_ability("pa_phantom_execution",c,3);local m=S.lua_modifier("modifier_rift_attack_cooldowns",c,a)
 a:StartCooldown(10);m:OnAttackLanded({attacker=c,target=u});T.eq(a:GetCooldownTimeRemaining(),9)
 local dagger=S.ability(4);function dagger:GetAbilityName()return "phantom_assassin_stifling_dagger" end
 m:OnAbilityFullyCast({unit=c,ability=dagger});T.eq(a:GetCooldownTimeRemaining(),7)
 m:OnAttackLanded({attacker=c,target=u,no_attack_cooldown=true});T.eq(a:GetCooldownTimeRemaining(),7)
end)
T.case("PA never-miss dagger can resolve before a deferred native attack event",function()
 local S=Stub.install();local c=S.hero("pa",0,2,Vector(0,0,0),{Damage=120})
 local u=S.hero("enemy",1,3,Vector(100,0,0),{})
 T.ok(require("rift.engine.pa_dagger_attack").perform(c,u,80,.75))
 u.props.AttackImmune=true;T.eq(require("rift.engine.pa_dagger_attack").perform(c,u,80,.75),false)
end)
T.case("PA magical launches only two daggers even in a crowd, preferring the nearest hero",function()
 local S=Stub.install();local c=S.hero("pa",0,2,Vector(0,0,0),{})
 local first=S.hero("first",1,3,Vector(100,0,0),{})
 local second=S.hero("second",2,3,Vector(110,0,0),{})
 S.hero("third",3,3,Vector(120,0,0),{});S.hero("fourth",4,3,Vector(130,0,0),{})
 local a=S.lua_ability("pa_storm_dagger",c,4);function a:GetCursorTarget()return first end
 a:OnSpellStart();T.eq(#S.projectiles,2);T.eq(S.projectiles[1].Target,first);T.eq(S.projectiles[2].Target,second)
end)
T.case("WR physical duration follows R rank 8/10/12",function()
 local E=require("rift.data.expansion");local Math=require("rift.core.path_math")
 for rank=1,3 do T.eq(Math.rank(E.abilities.rift_wr_physical.duration,rank),6+2*rank) end
end)
T.case("TA magic shield uses a native particle attached to the caster",function()
 local S=Stub.install();local c=S.hero("ta",0,2,Vector(0,0,0),{})
 local attachment,destroyed,released
 ParticleManager.SetParticleControlEnt=function(_,id,cp,entity,kind)
  attachment={id=id,cp=cp,entity=entity,kind=kind}
 end
 ParticleManager.DestroyParticle=function(_,id)destroyed=id end
 ParticleManager.ReleaseParticleIndex=function(_,id)released=id end
 local a=S.ability(4);local m=S.lua_modifier("modifier_rift_ta_refraction",c,a)
 T.eq(attachment.cp,1);T.eq(attachment.entity,c);T.eq(attachment.kind,PATTACH_ABSORIGIN_FOLLOW)
 m:OnDestroy();T.eq(destroyed,attachment.id);T.eq(released,attachment.id)
end)
T.case("TA physical Meld owns its native effect and restores the normal projectile on removal",function()
 local S=Stub.install();local c=S.hero("ta",0,2,Vector(0,0,0),{})
 local path,owner,released
 ParticleManager.CreateParticle=function(_,name,_,entity)path=name;owner=entity;return 91 end
 ParticleManager.ReleaseParticleIndex=function(_,id)released=id end
 local m=S.lua_modifier("modifier_rift_ta_meld",c,S.ability(4))
 T.eq(owner,c);T.eq(path,B.ta.meld_physical.effect);T.eq(m:GetModifierProjectileName(),B.ta.meld_physical.projectile)
 T.eq(m:GetModifierPreAttack_BonusDamage(),280)
 m:OnDestroy();T.eq(released,91);T.eq(m.meld_fx,nil)
end)
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
 c:SetAbsOrigin(Vector(10000,-7000,500));u:SetAbsOrigin(Vector(10100,-7000,500))
 local a=S.lua_ability("rift_lc_courage",c,4)
 local m=S.lua_modifier("modifier_rift_lc_courage",c,a)
 local fx,attachment,gesture,destroyed,released
 local retired={}
 local origins={}
 ParticleManager.SetParticleControl=function(_,id,cp,v)if cp==0 then origins[id]=v end end
 ParticleManager.CreateParticle=function(_,path,kind,owner)
  T.eq(owner,nil,"explicit stock effect contract")
  if path==B.lc.courage_physical.effect then fx={path=path,kind=kind,owner=owner};return 77 end
  T.eq(path,B.lc.courage_physical.effect_target);return 78
 end
 ParticleManager.SetParticleControlEnt=function(_,id,cp,entity)if cp==1 then attachment={id=id,cp=cp,entity=entity}end end
 ParticleManager.DestroyParticle=function(_,id)destroyed=id end
 ParticleManager.ReleaseParticleIndex=function(_,id)released=id;retired[id]=true end
 function c:StartGestureWithPlaybackRate(_,rate)gesture=rate end
 m:OnAttackLanded({attacker=u,target=c});T.eq(m.hits,0)
 for _=1,4 do m:OnAttackLanded({attacker=c,target=u}) end
 local perform=c.PerformAttack
 function c:PerformAttack(target,...)
  perform(self,target,...);m:OnAttackLanded({attacker=self,target=target})
  m:OnTakeDamage({attacker=self,unit=target,damage=100})
 end
 S.advance(.1);T.eq(#S.attacks,1);T.eq(m.hits,0);T.eq(c:GetHealth(),540)
 T.eq(fx.kind,PATTACH_WORLDORIGIN)
 T.eq(origins[77].x,c:GetAbsOrigin().x);T.eq(origins[78].x,u:GetAbsOrigin().x)
 T.eq(attachment.cp,1);T.eq(attachment.entity,c);T.ok(gesture>1)
 m:OnTakeDamage({attacker=c,unit=u,damage=100});T.eq(c:GetHealth(),540)
 S.advance(1);T.eq(destroyed,78);T.eq(released,78);T.ok(retired[77] and retired[78])
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
  local cases={pa_phantom_execution={24,20,16},lc_duel_physical={60,50,40},sf_requiem_physical={80,70,60},ta_psionic_crystal={10,9,8},ta_psionic_blast={14,12,10}}
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
    local visual={}
    function c:FadeGesture()visual[#visual+1]="fade"end
    function c:StartGestureWithPlaybackRate(_,rate)visual[#visual+1]="swing";T.ok(rate>1)end
    local perform=c.PerformAttack
    function c:PerformAttack(target,...) perform(self,target,...);m:OnAttackLanded({attacker=self,target=target}) end
    m:OnAttackLanded({attacker=c,target=u});S.advance(.2)
    T.eq(#S.attacks,1);T.eq(a:GetCooldown(rank-1),B.passives.sven_echo_cooldown[rank])
    T.eq(visual[1],"fade");T.eq(visual[2],"swing")
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
