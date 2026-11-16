-- Explicit single-player lab exercise. Never loaded by normal gameplay.
-- Cycles 1/3 test expiry; cycle 2 refreshes R after 8 seconds.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local lab=gm.lab;lab:Clear();lab.rank=3
assert(lab:Select("npc_dota_hero_nevermore","physical"))
local c,a,origin,started,cycle,step,last_second,refreshed
local ready=GameRules:GetGameTime()+40
local function cast()
 c:Stop();a:EndCooldown();c:GiveMana(a:GetManaCost(-1))
 c:CastAbilityNoTarget(a,lab.owner)
end
GameRules:GetGameModeEntity():SetContextThink("rift_sf_visual_watch",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime()
  if not c then
   assert(now<ready,"precache timeout")
   if lab.loading then return .1 end
   c=PlayerResource:GetSelectedHeroEntity(lab.owner)
   assert(c and c:GetUnitName()=="npc_dota_hero_nevermore","SF selection failed")
   a=c:FindAbilityByName("sf_requiem_physical");assert(a,"physical R missing")
   origin=c:GetAbsOrigin();cycle=0;started=now-30
  end
  if c:IsNull() or PlayerResource:GetSelectedHeroEntity(lab.owner)~=c then return nil end
  if now-started>=28 then
   cycle=cycle+1
   if cycle>3 then c:Stop();print("[RIFT][SF_WATCH] DONE");return nil end
   started=now;step=-1;last_second=-1;refreshed=false;cast()
   print("[RIFT][SF_WATCH] cycle="..cycle.." CAST")
  end
  local elapsed=now-started
  local second=math.floor(elapsed)
  if second~=last_second then
   last_second=second
   local m=c:FindModifierByName("modifier_rift_sf_spheres")
   print(string.format("[RIFT][SF_WATCH] cycle=%d t=%d active=%s remaining=%.2f charges=%d",cycle,second,tostring(m~=nil),m and m:GetRemainingTime()or 0,m and m:GetStackCount()or 0))
  end
  local waypoint=math.floor(elapsed/3)
  if waypoint~=step then
   step=waypoint
   local offsets={Vector(300,0,0),Vector(300,250,0),Vector(0,250,0),Vector(0,0,0)}
   c:MoveToPosition(origin+offsets[waypoint%4+1])
  end
  if cycle==2 and elapsed>=8 and not refreshed then refreshed=true;cast();print("[RIFT][SF_WATCH] REFRESH") end
  return .1
 end)
 if not ok then print("[RIFT][SF_WATCH] ERROR "..tostring(result));return nil end
 return result
end,.1)
