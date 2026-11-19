local B=require("rift.data.hero_balance")
local C=require("rift.core.progression")
local Refund=require("rift.core.attack_refund")
local Stub=require("engine_stub")
T.case("flat and percent reductions share the original cooldown budget in either order",function()
 T.eq(C.cooldown(16,{ult_cooldown_pct=10},B.progression,11),12)
 T.eq(C.cooldown(40,{ult_cooldown_pct=10},B.progression,8),30)
 T.eq(C.cooldown(30,{ult_cooldown_pct=-50},B.progression,-20),30)
 T.eq(C.cooldown(30,{},B.progression,4),26)
end)
for hero,paths in pairs(B.progression.heroes)do for path,def in pairs(paths)do
 T.case(hero.." "..path..": all talents and both Aghanim cannot bypass static cooldown budget",function()
  local b=C.total(def,{true,true,true,true,true,true,true,true},true,true)
  for _,base in ipairs({8,16,30,40,60,100})do
   for _,flat in ipairs({0,2,4,12,100})do
    local cd=C.cooldown(base,b,B.progression,flat)
    T.ok(cd>=base*.75 and cd<=base)
   end
  end
 end)
end end
T.case("one series cannot refund more than its shared budget even with twelve real heroes",function()
 local spent=0
 for _=1,12 do spent=spent+Refund.amount(2,true,.2,spent,7.5)end
 T.eq(spent,7.5)
 T.eq(Refund.amount(2,true,.2,spent,7.5),0)
 T.eq(Refund.amount(2,false,.2,0,7.5),.4)
end)
T.case("delayed Juggernaut attack records retain one pooled session and cannot refund twice",function()
 local S=Stub.install();local c=S.hero("jug",0,2,Vector(0,0,0),{})
 local u=S.hero("enemy",1,3,Vector(100,0,0),{})
 local a=S.ability(3);function a:GetAbilityName()return "rift_juggernaut_physical"end
 local m=S.lua_modifier("modifier_rift_attack_cooldowns",c,a)
 local ctx={spent=0,cap=7.5};c._rift_sleight_attack=true;c._rift_sleight_context=ctx
 for i=1,12 do m:OnAttackRecord({attacker=c,record=i})end
 c._rift_sleight_attack=nil;c._rift_sleight_context=nil;a:StartCooldown(30)
 for i=12,1,-1 do
  local ev={attacker=c,target=u,record=i,no_attack_cooldown=true}
  m:OnAttackLanded(ev);m:OnAttackLanded(ev);m:OnAttackRecordDestroy(ev)
 end
 T.eq(ctx.spent,7.5);T.eq(a:GetCooldownTimeRemaining(),22.5);T.eq(next(m.sleight_records),nil)
end)
T.case("ordinary creep and illusion attacks give only one fifth of hero CDR",function()
 local S=Stub.install();local c=S.hero("pa",0,2,Vector(0,0,0),{})
 local creep=S.unit("creep",{team=3,pos=Vector(100,0,0)})
 local u=S.hero("enemy",1,3,Vector(100,0,0),{});function u:IsIllusion()return true end
 local a=S.lua_ability("pa_phantom_execution",c,3);local m=S.lua_modifier("modifier_rift_attack_cooldowns",c,a)
 a:StartCooldown(10);m:OnAttackLanded({attacker=c,target=creep});m:OnAttackLanded({attacker=c,target=u})
 T.ok(math.abs(a:GetCooldownTimeRemaining()-9.6)<.00001)
 function u:IsIllusion()return false end;m:OnAttackLanded({attacker=c,target=u});T.ok(math.abs(a:GetCooldownTimeRemaining()-8.6)<.00001)
end)
T.case("SF all upgrades keep a cooldown gap with 25 percent native item CDR",function()
 local d=B.progression.heroes.npc_dota_hero_nevermore.physical
 local b=C.total(d,{true,true,true,true,true,true,true,true},true,true)
 local duration=B.sf.requiem_physical.duration+b.sf_duration
 local cd=C.cooldown(30,b,B.progression,4)*.75
 T.eq(duration,17);T.eq(cd,19.5);T.ok(cd>duration)
end)
