local E = require("rift.data.expansion")
local Math = require("rift.core.path_math")
local Stub = require("engine_stub")
local Registry = require("rift.core.upgrade_registry")
local Effects = require("rift.core.upgrade_effects")

local function setup(name)
  local S = Stub.install()
  local d = E.abilities[name]
  local c = S.hero(d.hero, 0, 2, Vector(0, 0, 0),
    { Damage = 120, Strength = 40, Intellect = 50, Agility = 60, MaxHealth = 2000, Health = 1000 })
  local u = S.hero("enemy", 1, 3, Vector(150, 0, 0), { Health = 1200, MaxHealth = 2000 })
  package.loaded["rift.abilities.path_ultimate"] = nil
  require("rift.abilities.path_ultimate")
  local a = S.ability(2)
  function a:GetCaster() return c end
  function a:GetCursorTarget() return u end
  function a:GetCursorPosition() return Vector(400, 0, 0) end
  function a:GetAbilityName() return name end
  setmetatable(a, { __index = _G[name] })
  return S, c, u, a, d
end

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
    T.case(name .. " executes its complete bounded combat loop", function()
      local S, c, u, a, d = setup(name)
      a:OnSpellStart()
      if d.mode == "stance" then
        local mod = S.lua_modifier("modifier_rift_path_stance", c, a)
        for _ = 1, d.every do mod:OnAttackLanded({attacker=c,target=u}) end
        T.eq(mod:GetStackCount(), 0)
        T.eq(#S.damage,1)
        S.advance(10)
      else
        -- Aim zones/lines at the target in this integration smoke test.
        if d.target == "point" then u:SetAbsOrigin(Vector(400,0,0)) end
        S.advance(10)
        T.eq(#S.damage, d.ticks or 1)
        local expected = Math.damage(d,2,{attack=120,strength=40,intellect=50,agility=60})
        if d.mode == "verdict" then expected = expected + 800*d.missing_health end
        if d.distance_bonus then expected = expected * (1+d.distance_bonus*400/d.range) end
        T.ok(math.abs(S.damage[1].damage-expected)<0.001, "snapshot damage")
      end
      T.ok(next(S.thinks)==nil, "all thinks and particle cleanup complete")
    end)
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
T.case("Axe verdict cleaves once and refunds only half the remaining cooldown on a real hero kill",function()
  local S,_,u,a,d=setup("rift_axe_physical")
  S.hero("nearby",2,4,Vector(170,0,0),{Health=2000,MaxHealth=2000})
  a:StartCooldown(20)
  _G.ApplyDamage=function(ev)
    S.damage[#S.damage+1]=ev
    if ev.victim==u then u.dead=true end
    return ev.damage
  end
  a:OnSpellStart()
  T.eq(#S.damage,2)
  T.eq(S.damage[2].damage,S.damage[1].damage*d.cleave)
  T.eq(a:GetCooldownTimeRemaining(),10)
end)
T.case("killing an illusion does not refund Axe verdict cooldown",function()
  local S,_,u,a=setup("rift_axe_physical")
  function u:IsIllusion() return true end
  a:StartCooldown(20)
  _G.ApplyDamage=function(ev) u.dead=true; return ev.damage end
  a:OnSpellStart()
  T.eq(a:GetCooldownTimeRemaining(),20)
end)
