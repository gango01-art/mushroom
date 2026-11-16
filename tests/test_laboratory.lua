local F=require("lab_fixture")
local Policy=require("rift.core.laboratory")
local Config=require("rift.core.config")
-- Every supported hero, all three paths, all R ranks. This exercises the real
-- server adapters on the stub; it does not certify Valve assets or rendering.
for _,name in ipairs(Policy.roster(require("rift.core.upgrade_registry").new(
  require("rift.data.upgrades"),require("rift.data.ultimate_directions"),
  {handlers=require("rift.core.upgrade_effects").HANDLERS}))) do
 for _,path in ipairs({"base","physical","magical"}) do
  for _,rank in ipairs({1,2,3}) do
   T.case(name.." "..path.." R"..rank..": fresh hero, rank, slots and no previous abilities",function()
    local f=F.setup();T.ok(f.gm.lab:Start(0))
    local old=f.selected[0];old:AddAbility("old_hero_leak_probe")
    f.gm.lab.rank=rank
    local ok,why=f.gm.lab:Select(name,path);T.ok(ok,why)
    local h=f.selected[0]
    T.ok(old:IsNull());T.eq(h:GetUnitName(),name);T.eq(h:GetLevel(),25)
    T.eq(h:FindAbilityByName("old_hero_leak_probe"),nil)
    T.eq(h:GetAbilityByIndex(5):GetAbilityType(),ABILITY_TYPE_ULTIMATE,"ultimate stays on R")
    T.ok(not h:GetAbilityByIndex(5):IsHidden())
    T.eq(h:GetAbilityByIndex(5):GetLevel(),rank)
    local directions=f.gm.upgrades.registry:hero_directions(name)
    T.eq(f.gm.upgrades:DirectionId(0),path~="base" and directions[path].id or nil)
    T.eq(f.gm.upgrades.offers:visible(0),nil)
   end)
  end
 end
end
T.case("player cosmetics finish precaching before any old hero is removed",function()
 local f=F.setup();f.gm.lab:Start(0);local old=f.selected[0]
 f.defer_precache=true
 local ok,why=f.gm.lab:Select("npc_dota_hero_axe","magical")
 T.ok(ok);T.eq(why,"loading");T.ok(f.gm.lab.loading)
 T.eq(f.selected[0],old);T.ok(not old:IsNull())
 T.eq(f.precaches[#f.precaches].pid,0)
 T.eq(f.precaches[#f.precaches].hero,"npc_dota_hero_axe")
 f.precache_callback()
 T.ok(not f.gm.lab.loading);T.ok(old:IsNull())
 T.eq(f.selected[0]:GetUnitName(),"npc_dota_hero_axe")
 T.eq(f.gm.upgrades:DirectionId(0),"rift_axe_magical")
 local count=#f.precaches
 local previous=f.selected[0]
 T.ok(f.gm.lab:Select("npc_dota_hero_axe","physical"));T.eq(#f.precaches,count+1)
 T.eq(f.selected[0],previous);T.ok(not previous:IsNull());T.ok(f.gm.lab.loading)
 f.precache_callback();T.ok(previous:IsNull());T.eq(f.gm.upgrades:DirectionId(0),"rift_axe_physical")
end)
T.case("hero and rank clicks cannot race an in-progress resource load",function()
 local f=F.setup();f.gm.lab:Start(0);f.defer_precache=true
 f.gm.lab:Select("npc_dota_hero_axe","magical");local rank=f.gm.lab.rank
 local ok,why=f.gm.lab:Select("npc_dota_hero_lina","physical")
 T.ok(not ok);T.eq(why,"loading")
 f.gm.lab:Request({PlayerID=0,action="rank",rank=1})
 T.eq(f.gm.lab.rank,rank)
 f.precache_callback();T.eq(f.selected[0]:GetUnitName(),"npc_dota_hero_axe")
end)
T.case("precache timeout keeps the old hero and ignores late callbacks",function()
 local f=F.setup();f.gm.lab:Start(0);local old=f.selected[0];f.defer_precache=true
 f.gm.lab:Select("npc_dota_hero_axe","base");local late=f.precache_callback
 f.stub.advance(Config.lab.precache_timeout_seconds+1)
 T.ok(not f.gm.lab.loading);T.eq(f.selected[0],old);T.ok(not old:IsNull())
 f.gm.lab:Select("npc_dota_hero_lina","magical");local fresh=f.precache_callback
 late();T.eq(f.selected[0],old)
 fresh();T.eq(f.selected[0]:GetUnitName(),"npc_dota_hero_lina")
end)
T.case("precache API failure never replaces or removes the current hero",function()
 local f=F.setup();f.gm.lab:Start(0);local old=f.selected[0]
 _G.PrecacheUnitByNameAsync=function() error("resource load unavailable") end
 local ok,why=f.gm.lab:Select("npc_dota_hero_axe","base")
 T.ok(not ok);T.eq(why,"precache_failed");T.eq(f.selected[0],old)
 T.ok(not old:IsNull());T.ok(not f.gm.lab.loading)
end)
T.case("lab start prepares 11 gallery actors, target, level 25 and no direction offer",function()
 local f=F.setup();local ok=f.gm.lab:Start(0);T.ok(ok)
 T.eq(#f.gm.lab.gallery,11);T.eq(#f.gm.lab.targets,1)
 T.eq(f.selected[0]:GetLevel(),25);T.eq(f.selected[0].props.AbilityPoints,0)
 T.ok(f.relic_ended);T.eq(f.gm.upgrades.offers:visible(0),nil)
 for _,u in ipairs(f.gm.lab.gallery) do T.ok(u:HasModifier("modifier_rift_lab_display"));T.eq(u:GetLevel(),25) end
end)
T.case("all 22 paths can be selected successively on fresh assigned heroes",function()
 local f=F.setup();T.ok(f.gm.lab:Start(0))
 for _,d in ipairs(f.gm.upgrades.registry.directions) do
  local old=f.selected[0]
  local ok,why=f.gm.lab:Select(d.hero_id,d.direction);T.ok(ok,why)
  T.ok(old:IsNull());T.eq(f.selected[0]:GetUnitName(),d.hero_id)
  T.eq(f.gm.upgrades:DirectionId(0),d.id)
  T.eq(f.gm.upgrades.directions.applied[0],d.id)
 end
end)
T.case("gallery replacement removes old actors instead of growing without a bound",function()
 local f=F.setup();f.gm.lab:Start(0)
 local old=f.gm.lab.gallery
 T.ok(f.gm.lab:Gallery("physical"));T.eq(#f.gm.lab.gallery,11)
 for _,u in ipairs(old) do T.ok(u:IsNull()) end
 T.ok(f.gm.lab:Gallery("magical"));T.eq(#f.gm.lab.gallery,11)
 f.gm.lab:Clear();T.eq(#f.gm.lab.gallery,0);T.eq(#f.gm.lab.targets,0)
end)
T.case("normal PvP, multiple players, unknown players and non-host are refused",function()
 local f=F.setup();f.gm.dev=false;T.ok(not f.gm.lab:Start(0))
 f.gm.dev=true;f.count=2;T.ok(not f.gm.lab:Start(0))
 f.count=1;T.ok(not f.gm.lab:Start(9))
 f.host=false;T.ok(not f.gm.lab:Start(0));T.ok(not f.gm.lab.enabled)
end)
T.case("target limit and payload validation reject client-supplied entities and heroes",function()
 local f=F.setup();f.gm.lab:Start(0)
 for _=2,Config.lab.max_targets do T.ok(f.gm.lab:Target("mortal")) end
 local ok,why=f.gm.lab:Target("immortal");T.ok(not ok);T.eq(why,"target_limit")
 T.ok(not Policy.validate({action="select",hero="npc_dota_hero_invoker",path="physical"},f.gm.lab.known))
 T.ok(not Policy.validate({action="select",hero=f.gm.lab.hero,path="anything"},f.gm.lab.known))
 T.ok(not Policy.validate({action="rank",rank=99},f.gm.lab.known))
 T.ok(not Policy.validate({action="target",kind="unknown"},f.gm.lab.known))
end)
T.case("lab request rate limiting prevents repeated hero replacements",function()
 local f=F.setup();f.gm.lab:Start(0)
 local args={PlayerID=0,action="select",hero="npc_dota_hero_axe",path="physical"}
 f.gm.lab:Request(args);local selected=f.selected[0]
 f.gm.lab:Request(args);T.eq(f.selected[0],selected)
 f.stub.now=1;f.gm.lab:Request(args);T.ok(f.selected[0]~=selected)
end)
T.case("old offers cannot resolve after a lab reset",function()
 local f=F.setup();local offers=f.gm.upgrades.offers
 local o=offers:dev_issue_regular(0,0,0);T.ok(o)
 f.gm.lab:Start(0)
 local ok=offers:choose(0,o.id,o.options[1],0);T.ok(not ok)
 T.eq(next(offers:player(0).build),nil)
end)
T.case("rank switch rebuilds a clean hero and native mode removes custom paths",function()
 local f=F.setup();f.gm.lab:Start(0);f.gm.lab.rank=1
 T.ok(f.gm.lab:Select("npc_dota_hero_axe","magical"))
 T.eq(f.selected[0]:FindAbilityByName("rift_axe_magical"):GetLevel(),1)
 T.ok(f.gm.lab:Select("npc_dota_hero_axe","base"))
 T.eq(f.selected[0]:FindAbilityByName("rift_axe_magical"),nil)
 T.eq(f.selected[0]:FindAbilityByName("axe_culling_blade"):GetLevel(),1)
 T.eq(f.gm.upgrades:DirectionId(0),nil)
end)
T.case("blocked terrain yields no placement rather than spawning on a cliff",function()
 local cfg=Config.lab
 local p=Policy.walkable(cfg,{x=0,y=0,z=0},function() return false end,{})
 T.eq(p,nil)
 local q=Policy.walkable(cfg,{x=0,y=0,z=0},function() return true end,{{x=0,y=0}})
 T.ok(q and q.x*q.x+q.y*q.y>=cfg.placement_separation^2)
end)
T.case("lab thinker suspends match progression past eighteen minutes",function()
 local f=F.setup();f.gm.lab:Start(0)
 f.stub.now=2000
 f.gm.director.tick=function() error("director must not run in the lab") end
 local interval=require("rift.engine.game_mode").Think(f.gm)
 T.eq(interval,0.25);T.ok(f.gm.director.state:is("ACTIVE"))
end)
T.case("switching a hero clears only that hero's summons",function()
 local f=F.setup();f.gm.lab:Start(0)
 local old=f.selected[0]
 local owned=f.stub.unit("owned");function owned:GetOwner() return old end
 local other=f.stub.unit("other");function other:GetOwner() return nil end
 f.summons={owned,other}
 T.ok(f.gm.lab:Select("npc_dota_hero_axe","physical"))
 T.ok(owned:IsNull());T.ok(not other:IsNull())
end)
T.case("mortal target kills advance LC magic once without match score",function()
 local f=F.setup();f.gm.lab:Start(0)
 T.ok(f.gm.lab:Select("npc_dota_hero_legion_commander","magical"))
 T.ok(f.gm.lab:Target("mortal"))
 local victim=f.gm.lab.targets[#f.gm.lab.targets];victim.dead=true
 f.gm.lab:OnKilled(victim,f.selected[0]);f.gm.lab:OnKilled(victim,f.selected[0])
 T.eq(require("rift.engine.lc_magic").owner_state(0).earned,1)
end)
T.case("console hero aliases resolve only supported heroes",function()
 local f=F.setup()
 T.eq(Policy.resolve_hero("sf",f.gm.lab.known),"npc_dota_hero_nevermore")
 T.eq(Policy.resolve_hero("lina",f.gm.lab.known),"npc_dota_hero_lina")
 T.eq(Policy.resolve_hero("npc_dota_hero_invoker",f.gm.lab.known),nil)
end)
T.case("old TA wave callbacks ignore a removed lab hero",function()
 local S=require("engine_stub").install()
 local Waves=require("rift.engine.ta_waves")
 local c=S.hero("npc_dota_hero_templar_assassin",0,2,Vector(0,0,0),{})
 local target=S.hero("target",1,3,Vector(100,0,0),{})
 local ability=S.ability(1);function ability:GetCaster() return c end
 local id=Waves.store:release(c:entindex(),120,50,0.6,S.now,2)
 c.removed=true
 Waves.hit(ability,target,{wave_id=id})
 T.eq(#S.damage,0)
end)
