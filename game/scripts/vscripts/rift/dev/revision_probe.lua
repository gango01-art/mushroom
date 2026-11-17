-- Explicit single-player native audit after rebuilding the map and restarting.
local gm=GameRules.RiftArena
assert(gm and gm.dev and PlayerResource:GetPlayerCount()==1 and not gm.lab.enabled)
local h=assert(PlayerResource:GetSelectedHeroEntity(0))
local function log(s)print("[RIFT][REVISION_NATIVE] "..s)end
for i,p in ipairs(gm.map.roshan_pockets)do
 local v=GetGroundPosition(Vector(p.x,p.y,p.z),nil)
 log("pit="..i.." z="..v.z.." clear="..tostring(GridNav:IsTraversable(v)and not GridNav:IsBlocked(v)).." connected="..tostring(GridNav:CanFindPath(Vector(0,0,128),v)))
 assert(math.abs(v.z-p.z)<2,"pit floor must match its authored height")
 assert(GridNav:IsTraversable(v)and not GridNav:IsBlocked(v),"pit center blocked")
 assert(GridNav:CanFindPath(Vector(0,0,128),v),"pit disconnected")
 for j=0,7 do local a=j*math.pi/4;local q=GetGroundPosition(v+Vector(math.cos(a)*180,math.sin(a)*180,0),nil)
  assert(math.abs(q.z-v.z)<32 and GridNav:IsTraversable(q)and not GridNav:IsBlocked(q),"pit fighting area broken: "..i.." probe "..j)
 end
 log("pit="..i.." all eight inner floor samples pass")
end
local radialPass, radialOpen = 0, 0
for i=0,31 do
 local angle=i*math.pi/16
 local direction=Vector(math.cos(angle),math.sin(angle),0)
 local inner=GetGroundPosition(direction*800,nil)
 local outer=GetGroundPosition(direction*1000,nil)
 if GridNav:IsTraversable(inner) and not GridNav:IsBlocked(inner)
    and GridNav:IsTraversable(outer) and not GridNav:IsBlocked(outer) then
  radialOpen=radialOpen+1
  if GridNav:CanFindPath(inner,outer) and GridNav:FindPathLength(inner,outer)<290 then
   radialPass=radialPass+1
  end
 end
end
log("center crossings direct="..radialPass.." clear_endpoints="..radialOpen.." samples=32")
assert(radialPass>0,"central boundary has no direct crossing")
local c=assert(require("rift.engine.couriers").ensure(gm,h,0),"courier missing")
assert(c:IsCourier()and c:GetPlayerOwnerID()==0 and c:IsInvulnerable())
assert(require("rift.engine.couriers").ensure(gm,h,0)==c,"duplicate courier")
log("courier owner=0 invulnerable=true idempotent=true")
local u=assert(gm.roshan.unit)
for _,name in ipairs(require("rift.core.config").roshan.abilities)do
 local a=assert(u:FindAbilityByName(name),name);assert(a:GetLevel()==1)
 log("Roshan native "..name.." level=1")
end
local spell=h:GetAbilityByIndex(0)
assert(u:TriggerSpellAbsorb(spell),"native Roshan spell block did not absorb")
assert(not u:TriggerSpellAbsorb(spell),"native spell block must have cooldown")
log("native Roshan spell block absorbs once, then cooldown PASS")
local before=c:GetHealth()
ApplyDamage({victim=c,attacker=u,damage=100000,damage_type=DAMAGE_TYPE_PURE})
assert(c:GetHealth()==before and c:IsAlive(),"courier protection failed")
log("courier resisted 100000 pure damage PASS")
require("rift.dev.arena_probe")
require("rift.dev.arena_route_probe")
require("rift.dev.arena_focus")
local startGold,startXP=PlayerResource:GetGold(0),h:GetCurrentXP()
local first=gm.director.state:active_elapsed(gm:Now())
GameRules:GetGameModeEntity():SetContextThink("rift_revision_income",function()
 local last=gm.director.state:active_elapsed(gm:Now())
 local cfg=require("rift.core.config")
 local rules=require("rift.core.rules")
 local expectedGold,expectedXP=rules.accumulate(rules.new_accumulator(),cfg,last-first,nil,last)
 local extra=require("rift.core.center_gold").distribute({}, {0},cfg.center_gold.phases,first,last)[0]or 0
 local gold,xp=PlayerResource:GetGold(0)-startGold,h:GetCurrentXP()-startXP
 log(string.format("center %.1fs gold=%d expected=%d xp=%d expected=%d",last-first,gold,expectedGold+extra,xp,expectedXP))
 assert(math.abs(gold-(expectedGold+extra))<=3 and math.abs(xp-expectedXP)<=6,"center income or passive XP stopped")
 assert(h:HasModifier("modifier_rift_center_gold"),"center gold modifier missing")
 PlayerResource:SetCameraTarget(0,nil)
 log("DONE; navigation, all-team vision, center gold and passive XP checked")
end,4)
