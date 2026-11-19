local Rules=require("rift.core.rules")
local Core=require("rift.core.center_gold")
local Service=require("rift.engine.center_gold")
local Stub=require("engine_stub")
T.case("30-minute passive economy milestones and phase crossing are exact",function()
 local cfg=T.config();T.eq(cfg.match.active_seconds,1800);T.eq(cfg.economy.start_gold,600)
 for _,p in ipairs({{240,1560},{600,4440},{900,7440},{1200,10440},{1500,14640},{1800,18840}})do
  T.eq(600+Rules.income_between(cfg.economy.passive_gold_phases,0,p[1]),p[2])
 end
 T.eq(Rules.income_between(cfg.economy.passive_gold_phases,239,241),12)
 local a=Rules.new_accumulator();local total=0
 for i=1,7200 do local g=Rules.accumulate(a,cfg,.25,nil,i*.25);total=total+g end
 T.eq(total,18240);T.eq(Rules.income_between(cfg.economy.passive_gold_phases,50,50),0)
end)
T.case("central pool is shared, fractions conserved, and empty time creates no bank",function()
 local b=T.config().center_gold;local credits={};local totals={[0]=0,[1]=0,[2]=0}
 for i=1,120 do
  for pid,g in pairs(Core.distribute(credits,{0,1,2},b.phases,(i-1)*.25,i*.25))do totals[pid]=totals[pid]+g end
 end
 for pid=0,2 do T.eq(totals[pid],20)end
 T.eq(next(Core.distribute(credits,{},b.phases,30,100)),nil)
 T.eq(Core.distribute(credits,{0},b.phases,100,101)[0],2)
 T.eq(Core.distribute({}, {0},b.phases,599,601)[0],5)
end)
T.case("gold circle boundary is inclusive, no extension from model hull",function()
 T.ok(Core.inside({x=0,y=0},{x=900,y=0},900))
 T.ok(not Core.inside({x=0,y=0},{x=900.01,y=0},900))
end)
T.case("engine central gold excludes dead/outside/illusion and removes buff on exit",function()
 local S=Stub.install();local h=S.hero("hero",0,2,Vector(0,0,128),{})
 local e=S.hero("enemy",1,3,Vector(901,0,128),{})
 local grants={};local gm={players={[0]={},[1]={}},map={center={x=0,y=0,z=128}}}
 function gm:Grant(pid,gold)grants[pid]=(grants[pid]or 0)+gold end
 local zone=Service.new(gm);zone:tick(0,1);T.eq(grants[0],2);T.eq(grants[1],nil)
 T.ok(h:HasModifier("modifier_rift_center_gold"))
 h.pos=Vector(1000,0,128);e.pos=Vector(0,0,128);zone:tick(1,2)
 T.ok(not h:HasModifier("modifier_rift_center_gold"));T.eq(grants[1],2)
 e.dead=true;zone:tick(2,3);T.eq(grants[1],2);T.ok(not e:HasModifier("modifier_rift_center_gold"))
 e.dead=false;function e:IsIllusion()return true end;zone:tick(3,4);T.eq(grants[1],2)
end)
