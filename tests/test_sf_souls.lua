local Stub=require("engine_stub")
local function setup()
 local S=Stub.install();local c=S.hero("npc_dota_hero_nevermore",0,2,Vector(0,0,0),{})
 local u=S.hero("enemy",1,3,Vector(100,0,0),{})
 local a=S.ability(1);function a:GetAbilityName()return "nevermore_necromastery" end
 function a:GetSpecialValueFor(key)return key=="necromastery_max_souls" and 20 or 0 end
 c.abilities.nevermore_necromastery=a
 local native={stacks=0};function native:GetStackCount()return self.stacks end
 function native:SetStackCount(n)self.stacks=n end;function native:ForceRefresh()end
 c.mods.modifier_nevermore_necromastery=native
 local m=S.lua_modifier("modifier_rift_sf_soul_gain",c,a)
 return S,c,u,a,m,native
end
T.case("SF gains one soul on a landed enemy attack, not from allies, Break or illusions",function()
 local S,c,u,_,m,n=setup();m:OnAttackLanded({attacker=c,target=u});T.eq(n.stacks,1)
 u.team=2;m:OnAttackLanded({attacker=c,target=u});T.eq(n.stacks,1)
 u.team=3;c.broken=true;m:OnAttackLanded({attacker=c,target=u});T.eq(n.stacks,1)
end)
T.case("SF gets two souls once per successful raze even when multiple victims are hit",function()
 local S,c,u,_,m,n=setup();local a=S.ability(4);function a:GetAbilityName()return "nevermore_shadowraze1" end
 m:OnAbilityExecuted({unit=c,ability=a});T.eq(n.stacks,0,"empty cast has no reward")
 m:OnTakeDamage({attacker=c,unit=u,inflictor=a});m:OnTakeDamage({attacker=c,unit=u,inflictor=a});T.eq(n.stacks,2)
 local v=S.hero("other",2,3,Vector(100,0,0),{});m:OnTakeDamage({attacker=c,unit=v,inflictor=a});T.eq(n.stacks,2)
 m:OnAbilityExecuted({unit=c,ability=a});m:OnTakeDamage({attacker=c,unit=v,inflictor=a});T.eq(n.stacks,4)
 n.stacks=19;m:AddSouls(2);T.eq(n.stacks,20)
end)
T.case("SF overrides native kill gains to zero and retains seventy percent on death",function()
 local S,c,_,a,m,n=setup()
 for _,key in ipairs({"souls_per_kill","souls_per_hero_kill","shard_souls_per_kill"})do
  local ev={ability=a,ability_special_value=key};T.eq(m:GetModifierOverrideAbilitySpecial(ev),1);T.eq(m:GetModifierOverrideAbilitySpecialValue(ev),0)
 end
 T.eq(m:GetModifierOverrideAbilitySpecialValue({ability=a,ability_special_value="necromastery_soul_release"}),1)
 n.stacks=10;m:OnDeath({unit=c});S.advance(.01,.01);T.eq(n.stacks,7)
 require("rift.engine.sf_souls").on_death(c);S.advance(.02);T.eq(n.stacks,7,"duplicate native death events cannot deduct twice")
 T.eq(m:GetModifierOverrideAbilitySpecial({ability=a,ability_special_value="necromastery_max_souls"}),0)
end)
