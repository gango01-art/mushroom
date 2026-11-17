local Core=require("rift.core.sanctuary")
local Service=require("rift.engine.sanctuary")
local B=require("rift.core.config").sanctuary
local Stub=require("engine_stub")
T.case("sanctuary boundary belongs only to its team and has no exit grace",function()
 local bases={{team=2,x=0,y=0},{team=3,x=3000,y=0}}
 T.ok(Core.sheltered(bases,2,{x=B.radius,y=0},B.radius))
 T.ok(not Core.sheltered(bases,2,{x=B.radius+.01,y=0},B.radius))
 T.ok(not Core.sheltered(bases,3,{x=0,y=0},B.radius))
 T.eq(Core.home(bases,6),nil)
end)
local function scene()
 local S=Stub.install()
 local hero=S.hero("owner",0,2,Vector(0,0,0),{MaxHealth=2000,MaxMana=1000})
 local enemy=S.hero("enemy",1,3,Vector(1200,0,0),{})
 local gm={map={bases={{team=2,name="rift_base_2",x=0,y=0,z=128,tower={x=200,y=0,z=128}}}}}
 gm.sanctuary=Service.new(gm);GameRules.RiftArena=gm
 local function damage(a,u)return gm.sanctuary:filter_damage({entindex_attacker_const=a and a:entindex(),entindex_victim_const=u:entindex()})end
 return S,hero,enemy,gm,damage
end
T.case("base blocks lethal/ongoing incoming damage, outgoing damage and controlled-unit bypass",function()
 local S,h,e,gm,damage=scene()
 T.ok(not damage(e,h));T.ok(not damage(h,e));T.ok(not damage(nil,h))
 local pet=S.unit("pet",{pid=0,team=2,pos=Vector(1400,0,0)})
 T.ok(not damage(pet,e),"owner sheltered: no pet attack bypass")
 T.ok(damage(e,pet),"pet outside is not granted remote invulnerability")
 h.pos=Vector(800,0,0);T.ok(damage(h,e));T.ok(damage(e,h))
 pet.pos=Vector(0,0,0);T.ok(not damage(pet,e));T.ok(not damage(e,pet))
 local tower=S.unit("guardian",{team=2,pos=Vector(0,0,0)})
 T.ok(damage(tower,e),"autonomous guardian can fire from its base")
end)
T.case("hostile debuffs are blocked both ways but allied and intrinsic modifiers remain",function()
 local S,h,e,gm=scene()
 local function modifier(c,u)return gm.sanctuary:filter_modifier({entindex_caster_const=c:entindex(),entindex_parent_const=u:entindex()})end
 T.ok(not modifier(e,h));T.ok(not modifier(h,e));T.ok(modifier(h,h))
 h.pos=Vector(800,0,0);T.ok(modifier(h,e));T.ok(modifier(e,h))
end)
T.case("base buff restores max-health/mana fractions and performs a strong dispel",function()
 local S,h,e=scene();local calls=0
 function h:Purge(b,d,f,stuns,exceptions)T.eq(b,false);T.ok(d and stuns and exceptions);calls=calls+1 end
 local a=S.ability(1)
 local m=S.lua_modifier("modifier_rift_sanctuary",h,a)
 T.eq(m:GetModifierConstantHealthRegen(),400);T.eq(m:GetModifierConstantManaRegen(),200)
 m:OnIntervalThink();T.eq(calls,2)
end)
T.case("guardian hit uses its actual origin for smooth knockback, ignores unrelated attacks",function()
 local S,h,e=scene();local t=S.unit("guardian",{team=2,pos=Vector(300,200,128)})
 local m=S.lua_modifier("modifier_rift_base_guardian",t,S.ability(1))
 m:OnAttackLanded({attacker=h,target=e});T.ok(not e:HasModifier("modifier_knockback"))
 m:OnAttackLanded({attacker=t,target=e});local k=e.mods.modifier_knockback.kv
 T.eq(k.center_x,300);T.eq(k.center_y,200);T.eq(k.knockback_distance,B.knockback_distance)
 T.eq(k.duration,B.knockback_duration);T.ok(k.duration>0)
end)
T.case("fallback dev map has no sanctuary protections",function()
 local S,h,e,gm,damage=scene();gm.sanctuary=Service.new({map={fallback=true}})
 T.eq(#gm.sanctuary.bases,0);T.ok(damage(e,h));T.ok(damage(h,e))
end)
