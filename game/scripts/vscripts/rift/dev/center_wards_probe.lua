-- Explicit single-player Tools match; real income, real item casts and normal FoW.
local gm=GameRules.RiftArena;local pid=0
assert(gm and gm.dev and gm.lab:Allowed(pid)and not gm.lab.enabled,"single-player normal Tools match required")
assert(not gm.map.fallback and #gm.map.ward_spots==4,"recompiled arena required")
local h=assert(PlayerResource:GetSelectedHeroEntity(pid));local team=h:GetTeamNumber()
local home=assert(gm.sanctuary:home(team));local saved=h:GetAbsOrigin()
local function log(s)print("[RIFT][CENTER_WARDS] "..s)end
local function gold()return PlayerResource:GetGold(pid)end
local function place(v)FindClearSpaceForUnit(h,GetGroundPosition(v,h),true);h:Stop()end
local function base()place(Vector(home.x,home.y,home.z))end
local function cleanup()
 h:Stop();PlayerResource:SetCameraTarget(pid,nil)
end
local elapsed=gm.director.state:active_elapsed(gm:Now())
local cfg=require("rift.core.config")
local expected=cfg.economy.start_gold+require("rift.core.rules").income_between(cfg.economy.passive_gold_phases,0,elapsed)
log("duration="..cfg.match.active_seconds.." start="..cfg.economy.start_gold.." wallet="..gold().." expected_passive_wallet="..expected)
-- The owner may already have earned center gold before loading this probe.
local function elapsed_now()return gm.director.state:active_elapsed(gm:Now())end
local expected_out= require("rift.core.rules").income_between(cfg.economy.passive_gold_phases,elapsed_now(),elapsed_now()+4)
local expected_in
GameRules:GetGameModeEntity():SetFogOfWarDisabled(false)
place(Vector(0,-1600,128))
local phase,at,start="outside",GameRules:GetGameTime()+4,gold()
local item,ward,index;local created={}
GameRules:GetGameModeEntity():SetContextThink("rift_center_wards_probe",function()
 local ok,result=pcall(function()
  local now=GameRules:GetGameTime();if now<at then return .05 end
  if phase=="outside"then
   local gain=gold()-start;log("outside 4s gold_gain="..gain);assert(math.abs(gain-expected_out)<=2,"passive rate incorrect")
   place(Vector(0,0,128));phase="settle";at=now+.5
  elseif phase=="settle"then
   start=gold();phase="inside";at=now+4
   expected_in=require("rift.core.rules").income_between(cfg.economy.passive_gold_phases,elapsed_now(),elapsed_now()+4)+require("rift.core.rules").income_between(cfg.center_gold.phases,elapsed_now(),elapsed_now()+4)
  elseif phase=="inside"then
   local gain=gold()-start;log("center 4s gold_gain="..gain.." buff="..tostring(h:HasModifier("modifier_rift_center_gold")))
   assert(math.abs(gain-expected_in)<=2 and h:HasModifier("modifier_rift_center_gold"),"central bonus incorrect")
   base();phase="before_wards";at=now+3
  elseif phase=="before_wards"then
   log("normal fog center_before_wards="..tostring(IsLocationVisible(team,Vector(0,0,128))))
   assert(IsLocationVisible(team,Vector(0,0,128)),"public center vision missing")
   for _,t in ipairs(gm.teams)do for i=0,15 do
    local a=i*math.pi/8
    assert(IsLocationVisible(t,Vector(math.cos(a)*880,math.sin(a)*880,128)),"public edge vision missing team="..t)
   end end
   log("public vision: 8 teams x 16 circle-edge samples PASS")
   item=h:FindItemInInventory("item_ward_observer")
   if not item then h:AddItem(CreateItem("item_ward_observer",h,h));item=h:FindItemInInventory("item_ward_observer")end
   assert(item,"observer could not be added");item:SetCurrentCharges(4)
   index=1;phase="place";at=now+.1
  elseif phase=="place"then
   local p=gm.map.ward_spots[index]
   local top=GetGroundPosition(Vector(p.x,p.y,p.z),nil)
   log("ward_pad="..index.." actual_z="..top.z.." walk_from_center="..tostring(GridNav:CanFindPath(Vector(0,0,128),top)))
   assert(top.z>=350,"ward pad did not compile")
   place(Vector(p.x,p.y,128)-Vector(p.x,p.y,0):Normalized()*320)
   item:EndCooldown();phase="cast";at=now+.5
  elseif phase=="cast"then
   local p=gm.map.ward_spots[index]
   log("cast hero="..tostring(h:GetAbsOrigin()).." distance="..(h:GetAbsOrigin()-Vector(p.x,p.y,p.z)):Length2D().." range="..item:GetCastRange(h:GetAbsOrigin(),nil))
   h:CastAbilityOnPosition(Vector(p.x,p.y,p.z),item,pid)
   phase="find_ward";at=now+1.4
  elseif phase=="find_ward"then
   local p=gm.map.ward_spots[index];ward=nil
   for _,u in ipairs(Entities:FindAllByClassname("npc_dota_ward_base"))do
    if u:GetTeamNumber()==team and (u:GetAbsOrigin()-Vector(p.x,p.y,p.z)):Length2D()<100 then ward=u;break end
   end
   assert(ward,"native observer item did not place on pad="..index.." charges="..tostring(item and not item:IsNull()and item:GetCurrentCharges()))
   created[#created+1]=ward;assert(ward:GetAbsOrigin().z>=350,"ward spawned below cliff")
   base();phase="vision";at=now+3
  elseif phase=="vision"then
   local visible=IsLocationVisible(team,Vector(0,0,128))
   log("ward="..index.." item_cast PASS z="..ward:GetAbsOrigin().z.." center_visible="..tostring(visible))
   local p=gm.map.ward_spots[index];local outward=Vector(p.x,p.y,0):Normalized()
   local approach=GetGroundPosition(Vector(p.x,p.y,0)+outward*800,nil)
   log("ward="..index.." approach_visible="..tostring(IsLocationVisible(team,approach)).." point="..approach.x..","..approach.y)
   assert(IsLocationVisible(team,approach),"cliff ward does not reveal its river approach")
   if index<4 then
    UTIL_Remove(ward);index=index+1;phase="place";at=now+2
   else
    cleanup();PlayerResource:SetCameraTarget(pid,ward)
    log("DONE wards4/4; real income matched current phases; normal fog; final ward left for screenshot")
    return nil
   end
  end
  return .05
 end)
 if not ok then log("ERROR "..tostring(result));cleanup();return nil end
 return result
end,.05)
