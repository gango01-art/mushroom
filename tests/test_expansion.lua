local E = require("rift.data.expansion")
local Math = require("rift.core.path_math")
local Stub = require("engine_stub")
local Registry = require("rift.core.upgrade_registry")
local Effects = require("rift.core.upgrade_effects")

local function setup(name,rank)
  local S = Stub.install()
  local d = E.abilities[name]
  local c = S.hero(d.hero, 0, 2, Vector(0, 0, 0),
    { Damage = 120, Strength = 40, Intellect = 50, Agility = 60, MaxHealth = 2000, Health = 1000 })
  local u = S.hero("enemy", 1, 3, Vector(150, 0, 0), { Health = 1200, MaxHealth = 2000 })
  package.loaded["rift.abilities.path_ultimate"] = nil
  require("rift.abilities.path_ultimate")
  local a = S.ability(rank or 2)
  function a:GetCaster() return c end
  function a:GetCursorTarget() return u end
  function a:GetCursorPosition() return Vector(400, 0, 0) end
  function a:GetAbilityName() return name end
  setmetatable(a, { __index = _G[name] })
  return S, c, u, a, d
end

T.case("Sven native impact follows its CP3 contract away from the world origin in both paths",function()
  for _,name in ipairs({"rift_sven_physical","rift_sven_magical"}) do
    local S,c,u,a,d=setup(name,3)
    c:SetAbsOrigin(Vector(10000,-7000,500));u:SetAbsOrigin(Vector(10150,-7000,500))
    local particles={}
    ParticleManager.CreateParticle=function(_,path)
      local p={path=path,controls={}};particles[#particles+1]=p;return #particles
    end
    ParticleManager.SetParticleControl=function(_,id,cp,value)particles[id].controls[cp]=value end
    if d.mode=="stance" then
      local m=S.lua_modifier("modifier_rift_path_stance",c,a)
      for _=1,d.every do m:OnAttackLanded({attacker=c,target=u}) end
    else
      require("rift.engine.path_combat").pulse({caster=c,ability=a,def=d,rank=3,
        stats={strength=40},point=u:GetAbsOrigin(),origin=c:GetAbsOrigin(),radius=d.radius},1)
    end
    local found=false
    for _,p in ipairs(particles) do
      if p.path=="particles/units/heroes/hero_sven/sven_storm_bolt_projectile_explosion.vpcf" then
        found=true;T.ok(p.controls[3],"native emission CP must be initialized")
        T.eq(p.controls[3].x,10150);T.eq(p.controls[3].y,-7000)
        T.eq(p.controls[3].z,500+(d.mode=="stance" and 24 or 64))
      end
    end
    T.ok(found)
  end
end)

T.case("Lina solar impact binds native ray endpoint to the cast away from world origin",function()
  local S,c,u,a,d=setup("rift_lina_magical",3)
  local particles={}
  ParticleManager.CreateParticle=function(_,path)
    particles[#particles+1]={path=path,controls={}};return #particles
  end
  ParticleManager.SetParticleControl=function(_,id,cp,value)particles[id].controls[cp]=value end
  local point=Vector(10000,-7000,500)
  require("rift.engine.path_combat").pulse({caster=c,ability=a,def=d,rank=3,
    stats={intellect=50},point=point,origin=point,radius=d.radius},1)
  T.ok(#particles>0)
  for _,p in ipairs(particles)do
    if p.path==d.particle then
      T.eq(p.controls[3].x,point.x);T.eq(p.controls[3].y,point.y)
      T.ok(p.controls[1].x<1000,"radius must not receive a world coordinate")
    end
  end
end)

T.case("alpha registry enables exactly eleven complete heroes", function()
  local reg = Registry.new(require("rift.data.upgrades"), require("rift.data.ultimate_directions"), { handlers = Effects.HANDLERS })
  T.eq(#reg:validate(), 0)
  local n = 0
  for hero in pairs(reg.dir_by_hero) do T.ok(reg:hero_enabled(hero)); n = n + 1 end
  T.eq(n, 11)
end)

T.case("beam geometry rejects behind, beyond and beside; clamps long casts", function()
  local origin, dir = {x=0,y=0}, {x=1,y=0}
  T.ok(Math.in_line({x=500,y=50},origin,dir,1000,100))
  T.ok(not Math.in_line({x=-10,y=0},origin,dir,1000,100))
  T.ok(not Math.in_line({x=1001,y=0},origin,dir,1000,100))
  T.ok(not Math.in_line({x=300,y=101},origin,dir,1000,100))
  local p = Math.clamp_point({x=3000,y=4000},origin,1000)
  T.eq(p.x,600); T.eq(p.y,800)
end)

for _, h in ipairs(E.heroes) do
  for _, path in ipairs({"physical", "magical"}) do
    local name = "rift_" .. h.key .. "_" .. path
    for _,rank in ipairs({1,2,3}) do
    T.case(name .. " R"..rank.." executes its complete bounded combat loop", function()
      local S, c, u, a, d = setup(name,rank)
      T.eq(a:GetCooldown(rank-1),d.cooldown[rank],"native cooldown getter uses zero-based rank")
      T.eq(a:GetManaCost(rank-1),d.mana[rank],"native mana getter uses zero-based rank")
      T.eq(a:GetCooldown(-1),d.cooldown[rank],"native -1 query uses the current rank")
      T.eq(a:GetManaCost(-1),d.mana[rank],"native current-rank mana query")
      a:OnSpellStart()
      if d.mode == "stance" then
        local mod = S.lua_modifier("modifier_rift_path_stance", c, a)
        for _ = 1, d.every do mod:OnAttackLanded({attacker=c,target=u}) end
        T.eq(mod:GetStackCount(), 0)
        if d.line then
          T.eq(#S.damage,0,"line damage waits for collision")
          for _,shot in ipairs(S.projectiles) do a:OnProjectileHit_ExtraData(u,nil,shot.ExtraData) end
        end
        T.eq(#S.damage,1)
        S.advance(10)
      elseif d.mode=="sleight" then
        S.advance(5);T.eq(#S.attacks,1);T.eq(S.attacks[1].target,u);T.eq(c:GetAbsOrigin():Length2D(),0)
      else
        -- Aim zones/lines at the target in this integration smoke test.
        if d.target == "point" then u:SetAbsOrigin(Vector(400,0,0)) end
        if d.mode=="barrage" or d.mode=="line" then
          for _=1,d.ticks do
            S.advance((d.delay or 0)+d.interval); local shots=S.projectiles;S.projectiles={}
            for _,shot in ipairs(shots) do
              a:OnProjectileHit_ExtraData(shot.Target or u,nil,shot.ExtraData)
              if not shot.Target then a:OnProjectileHit_ExtraData(shot.Target or u,nil,shot.ExtraData) end
            end
          end
        end
        S.advance(10)
        T.eq(#S.damage, d.ticks or 1)
        local expected = Math.damage(d,rank,{attack=120,strength=40,intellect=50,agility=60,attack_speed=100})
        if d.mode == "verdict" then expected = expected + 800*d.missing_health end
        if d.distance_bonus then expected = expected * (1+d.distance_bonus*400/d.range) end
        T.ok(math.abs(S.damage[1].damage-expected)<0.001, "snapshot damage")
      end
      T.ok(next(S.thinks)==nil, "all thinks and particle cleanup complete")
    end)
    end
  end
end

T.case("spell block prevents targeted cast and side effects", function()
  local S, _, u, a = setup("rift_pudge_physical")
  u.linkens=true; a:OnSpellStart(); S.advance(10)
  T.eq(#S.damage,0); T.ok(next(S.thinks)==nil)
end)
T.case("tether breaks on distance and does not resume on return", function()
  local S, _, u, a = setup("rift_pudge_physical")
  a:OnSpellStart(); S.advance(0.1); T.eq(#S.damage,1)
  u:SetAbsOrigin(Vector(1000,0,0)); S.advance(1)
  u:SetAbsOrigin(Vector(150,0,0)); S.advance(5); T.eq(#S.damage,1)
end)
T.case("caster death cancels delayed damage", function()
  local S, c, _, a = setup("rift_lina_magical")
  a:OnSpellStart(); c.dead=true; S.advance(10); T.eq(#S.damage,0)
end)
T.case("finished match cancels active zone", function()
  local S, _, u, a = setup("rift_cm_magical")
  u:SetAbsOrigin(Vector(400,0,0)); a:OnSpellStart(); S.advance(0.8)
  T.eq(#S.damage,1)
  GameRules.RiftArena={director={state={rewards_open=function() return false end}}}
  S.advance(10); T.eq(#S.damage,1)
end)
T.case("magic immunity blocks magic damage and control", function()
  local S, _, u, a = setup("rift_cm_magical")
  u:SetAbsOrigin(Vector(400,0,0)); u.immune=true; a:OnSpellStart(); S.advance(10)
  T.eq(#S.damage,0); T.ok(next(u.mods)==nil)
end)
T.case("stance never procs on allies or fabricated spell damage", function()
  local S, c, u, a, d = setup("rift_sven_physical")
  local mod=S.lua_modifier("modifier_rift_path_stance",c,a)
  u.team=c.team
  for _=1,10 do mod:OnAttackLanded({attacker=c,target=u}) end
  T.eq(#S.damage,0); T.eq(mod.hits,0)
  u.team=3
  for _=1,d.every do mod:OnAttackLanded({attacker=c,target=u}) end
  T.eq(#S.damage,1)
end)
T.case("FFA sustain cap is shared across victims per pulse", function()
  local S,c,u,a,d=setup("rift_axe_magical")
  u:SetAbsOrigin(Vector(400,0,0))
  S.hero("enemy2",2,4,Vector(400,0,0),{Health=1200,MaxHealth=2000})
  a:OnSpellStart();S.advance(0.7)
  T.eq(#S.damage,2)
  T.ok(c.props.Health<=1000+c.props.MaxHealth*d.heal_cap)
end)
T.case("Axe pull moves enemies inward once; immunity prevents movement but not physical damage",function()
  local S,c,u,a,d=setup("rift_axe_physical")
  u:SetAbsOrigin(Vector(400,0,0));a:OnSpellStart()
  T.eq(#S.damage,1);T.eq(u:GetAbsOrigin().x,400,"no teleport")
  local m=S.lua_modifier("modifier_rift_axe_pull",u,a,u.mods.modifier_rift_axe_pull.kv)
  m:UpdateHorizontalMotion(u,.175);T.eq(u:GetAbsOrigin().x,290)
  m:UpdateHorizontalMotion(u,.175);T.eq(u:GetAbsOrigin().x,180);T.ok(m.destroyed)
  u:SetAbsOrigin(Vector(400,0,0));u.immune=true;a:OnSpellStart()
  T.eq(#S.damage,2);T.eq(u:GetAbsOrigin().x,400)
end)
T.case("killing attack still triggers stance splash against another living hero",function()
  local S,c,u,a,d=setup("rift_sven_physical")
  local other=S.hero("nearby",2,4,Vector(160,0,0),{Health=2000,MaxHealth=2000})
  local mod=S.lua_modifier("modifier_rift_path_stance",c,a)
  mod.hits=d.every-1;u.dead=true
  mod:OnAttackLanded({attacker=c,target=u})
  T.eq(#S.damage,1);T.eq(S.damage[1].victim,other)
end)
T.case("Juggernaut cannot hit a snapshotted target that leaves the selected area",function()
  local S,_,u,a=setup("rift_juggernaut_physical")
  a:OnSpellStart();u:SetAbsOrigin(Vector(2500,0,0));S.advance(3)
  T.eq(#S.damage,0)
end)
T.case("point-target spells respect the caster's bonus cast range",function()
  local S,c,u,a=setup("rift_lina_magical")
  c.props.CastRangeBonus=300
  function a:GetCursorPosition() return Vector(1100,0,0) end
  u:SetAbsOrigin(Vector(1400,0,0))
  a:OnSpellStart();S.advance(1)
  T.eq(#S.damage,1,"first pulse reaches from bonus-range centre")
end)

T.case("AoE items expand hit geometry and preview equally without changing damage",function()
  local S,c,u,a,d=setup("rift_lina_magical",3)
  local item=S.ability(1)
  function item:GetAbilityName() return "item_shivas_guard" end
  function item:GetSpecialValueFor() return 75 end
  c.inventory[0]=item
  T.eq(a:GetAOERadius(),d.radius+37.5)
  u:SetAbsOrigin(Vector(400,d.radius+30,0))
  a:OnSpellStart();S.advance(1)
  T.eq(#S.damage,1)
  T.eq(S.damage[1].damage,75+50*.4)
end)
T.case("AoE items are unique by type, backpack excluded and narrow beams capped at 25 percent",function()
  local S,c,_,a,d=setup("rift_wr_magical")
  local function item(name)
    local i=S.ability(1);function i:GetAbilityName()return name end;function i:GetSpecialValueFor()return 75 end;return i
  end
  c.inventory[0]=item("item_shivas_guard");c.inventory[1]=item("item_shivas_guard")
  c.inventory[6]=item("item_gungir")
  T.eq(a:GetAOERadius(),187.5)
  c.inventory[2]=item("item_gungir");T.eq(a:GetAOERadius(),187.5)
end)
T.case("client-side AoE preview reads the replicated modifier without server inventory API",function()
  local S,c,_,a=setup("rift_lina_magical")
  c.GetItemInSlot=false
  c.FindModifierByName=false
  function c:GetModifierStackCount(name)T.eq(name,"modifier_rift_area_items");return 150 end
  T.eq(a:GetAOERadius(),405)
end)
T.case("Sven custom stun gets outgoing duration amplification once; Break disables it",function()
  local S,c,u,a=setup("rift_sven_magical")
  S.lua_ability("rift_sven_mystic_cleave",c,4)
  u:SetAbsOrigin(Vector(400,0,0));a:OnSpellStart();S.advance(1)
  T.ok(math.abs(u.mods.modifier_stunned.kv.duration-.87)<.0001)
  c.broken=true;a:OnSpellStart();S.advance(1)
  T.eq(u.mods.modifier_stunned.kv.duration,.75)
end)
T.case("Juggernaut storm continues on death, stays at death location and expires",function()
  local S,c,u,a,d=setup("rift_juggernaut_magical")
  a:OnSpellStart();S.advance(.2);c.dead=true;S.advance(.6)
  local count=#S.damage;T.ok(count>=2)
  c:SetAbsOrigin(Vector(3000,0,0));c.dead=false;S.advance(10)
  T.eq(#S.damage,d.ticks);T.ok(next(S.thinks)==nil)
end)
T.case("CM barrage hits all visible enemies per volley and duplicate callbacks cannot repeat damage",function()
  local S,_,u,a,d=setup("rift_cm_physical")
  local v=S.hero("other",2,4,Vector(-400,50,0),{})
  u:SetAbsOrigin(Vector(400,0,0));a:OnSpellStart();S.advance(.2)
  T.eq(#S.projectiles,2)
  for _,p in ipairs(S.projectiles) do a:OnProjectileHit_ExtraData(p.Target,nil,p.ExtraData);a:OnProjectileHit_ExtraData(p.Target,nil,p.ExtraData) end
  T.eq(#S.damage,2);T.eq(S.damage[2].victim,v)
end)
for rank=1,3 do
  T.case("WR physical attack speed R"..rank.." is the owner's 20/40/60",function()
    local S,c,_,a=setup("rift_wr_physical",rank)
    local m=S.lua_modifier("modifier_rift_path_stance",c,a)
    T.eq(m:GetModifierAttackSpeedBonus_Constant(),20*rank)
  end)
  T.case("Juggernaut CDR R"..rank.." counts landed hits, excludes allies/buildings and floors at zero",function()
    local S,c,u,a=setup("rift_juggernaut_physical",rank)
    local m=S.lua_modifier("modifier_rift_attack_cooldowns",c,a)
    a:StartCooldown(10);m:OnAttackLanded({attacker=c,target=u})
    T.eq(a:GetCooldownTimeRemaining(),9.9)
    u.team=c.team;local left=a:GetCooldownTimeRemaining();m:OnAttackLanded({attacker=c,target=u});T.eq(a:GetCooldownTimeRemaining(),left)
    u.team=3;c._rift_sleight_attack=true;a:StartCooldown(.2);m:OnAttackLanded({attacker=c,target=u});T.eq(a:GetCooldownTimeRemaining(),0)
  end)
end
