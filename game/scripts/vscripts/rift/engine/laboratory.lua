-- Single-player development laboratory. Uses the real selected hero for tests,
-- and separate parked copies for the whole-roster gallery. No normal-match RPC
-- can replace heroes, reset choices, mint gold or spawn units.
local Policy = require("rift.core.laboratory")
local Config = require("rift.core.config")
local Geometry = require("rift.core.arena")
local Mods = require("rift.engine.mods")
local Log = require("rift.engine.log")
local Lab = {}; Lab.__index=Lab
local function exists(u) return u and not u:IsNull() end
local function remove(u) if exists(u) then UTIL_Remove(u) end end

function Lab.new(gm)
  local self=setmetatable({gm=gm,enabled=false,gallery={},targets={},last_request={},rank=3,free=false,
    load_serial=0},Lab)
  self.roster,self.known=Policy.roster(gm.upgrades.registry)
  local settings=LoadKeyValues and LoadKeyValues("scripts/duality_local.kv") or {}
  self.autostart=gm.dev and settings and tostring(settings.auto_demo)=="1"
  CustomGameEventManager:RegisterListener("rift_lab_request",function(_,args) self:Request(args) end)
  return self
end
function Lab:Allowed(pid)
  if not self.gm.dev or PlayerResource:GetPlayerCount()~=1 then return false end
  local p=PlayerResource:GetPlayer(pid)
  if not p then return false end
  if not (IsInToolsMode and IsInToolsMode()) then
    if not GameRules:PlayerHasCustomGameHostPrivileges(p) then return false end
  end
  return not self.enabled or self.owner==pid
end
function Lab:Position(goal,reserved)
  local map=self.gm.map
  local function available(p)
    if map and not map.fallback and not Geometry.inside(p,map.bounds_min,map.bounds_max,160) then return false end
    local v=Vector(p.x,p.y,p.z or 0)
    return GridNav:IsTraversable(v) and not GridNav:IsBlocked(v)
  end
  local p=Policy.walkable(Config.lab,goal,available,reserved)
  return p and GetGroundPosition(Vector(p.x,p.y,p.z or 0),nil) or nil
end
function Lab:CleanupSessions(pid)
  local duel=require("rift.engine.lc_duel_session")
  local s=duel.sessions[pid]
  if s then duel.finish(s,s.duel:abort("owner_removed")) end
  duel.owners[pid]=nil
  local magic=require("rift.engine.lc_magic")
  local statue=magic.statues[pid]
  if statue then remove(statue.unit);statue.session.alive=false;magic.statues[pid]=nil end
  for id,rec in pairs(magic.by_id) do if rec.pid==pid then magic.by_id[id]=nil end end
  magic.owners[pid]=nil
end
function Lab:MaxAbilities(hero)
  while hero:GetLevel()<Config.lab.hero_level do hero:HeroLevelUp(false) end
  for i=0,hero:GetAbilityCount()-1 do
    local a=hero:GetAbilityByIndex(i)
    if a and not a:IsNull() and not a:GetAbilityName():find("special_bonus_",1,true) then
      local max=a:GetMaxLevel()
      if a:GetAbilityType()==ABILITY_TYPE_ULTIMATE then a:SetLevel(math.min(max,self.rank))
      elseif max>0 and max<=4 then a:SetLevel(max) end
    end
  end
  hero:SetAbilityPoints(4) -- native 10/15/20/25 talent choices remain testable
end
function Lab:Refresh(hero)
  if not exists(hero) then return end
  if not hero:IsAlive() then hero:RespawnHero(false,false) end
  hero:Purge(false,true,false,true,true)
  hero:SetHealth(hero:GetMaxHealth());hero:SetMana(hero:GetMaxMana())
  for i=0,hero:GetAbilityCount()-1 do
    local a=hero:GetAbilityByIndex(i)
    if a and not a:IsNull() then a:EndCooldown() end
  end
  for i=0,16 do
    local item=hero:GetItemInSlot(i)
    if item then item:EndCooldown() end
  end
end
function Lab:Select(hero_name,path)
  if not self.enabled or not self.known[hero_name] or not Policy.PATHS[path] then return false,"invalid_hero" end
  if self.loading then return false,"loading" end
  -- A previous callback is not a resource lifetime guarantee. Replacing the
  -- last instance can release player wearables; every replacement must await
  -- the engine again (including another path/rank of the same hero).
  -- The bootstrap precaches default units, not this player's equipped wearables.
  -- ReplaceHeroWith must wait for the player-specific models AND particles.
  -- The Axe crash dump was an access violation in particles.dll immediately
  -- after the engine reported nonresident axe_winter_2025 cosmetic models.
  if type(PrecacheUnitByNameAsync)~="function" then return false,"precache_failed" end
  local pid=self.owner
  self.load_serial=self.load_serial+1
  local serial=self.load_serial
  self.loading=true;self:Publish()
  local result
  local function complete(ok,why)
    if not self.loading or self.load_serial~=serial then return end
    self.loading=false
    result={ok,why}
    self.gm.upgrades:SendTo(pid,"rift_lab_result",{ok=ok and 1 or 0,reason=why})
    self:Publish()
  end
  GameRules:GetGameModeEntity():SetContextThink("rift_lab_load_"..pid,function()
    complete(false,"precache_failed")
    return nil
  end,Config.lab.precache_timeout_seconds)
  Log.info("LAB","precache player="..pid.." hero="..hero_name)
  local ran,err=pcall(PrecacheUnitByNameAsync,hero_name,function()
    if not self.loading or self.load_serial~=serial then return end
    if not self:Allowed(pid) then complete(false,"not_allowed");return end
    local called,ok,why=pcall(self.SelectReady,self,hero_name,path)
    if not called then Log.error("LAB",ok);complete(false,"internal_error")
    else complete(ok,why) end
  end,pid)
  if not ran then Log.error("LAB",err);complete(false,"precache_failed") end
  if result then return result[1],result[2] end
  return true,"loading"
end
function Lab:SelectReady(hero_name,path)
  local pid=self.owner
  local old=PlayerResource:GetSelectedHeroEntity(pid)
  self:CleanupSessions(pid)
  -- TA crystals / PA spirits and native summoned creatures belong to the old
  -- hero entity, not to its replacement. Remove only that owner's creatures.
  if exists(old) then
    for _,u in ipairs(Entities:FindAllByClassname("npc_dota_creature")) do
      if exists(u) and u:GetOwner()==old then remove(u) end
    end
  end
  -- The engine assigns the new hero to the player; selecting a pet/gallery copy
  -- alone would leave old per-player direction handlers attached to another unit.
  local hero=PlayerResource:ReplaceHeroWith(pid,hero_name,Config.lab.gold,0)
  if not exists(hero) then return false,"spawn_failed" end
  self.hero,self.path,self.unit=hero_name,path,hero
  if self.gm.ids then self.gm.ids:on_spawn(hero:entindex(),tostring(hero)) end
  if old~=hero then remove(old) end
  -- Keep each test fresh: inventory, build, hidden natives and earned LC state
  -- must not carry over between unrelated heroes/paths.
  for i=0,16 do local item=hero:GetItemInSlot(i);if item then hero:RemoveItem(item);remove(item) end end
  self.gm.upgrades.offers:reset_player(pid,hero_name)
  self.gm.upgrades.directions.locked[pid]=nil
  self.gm.upgrades.directions.applied[pid]=nil
  self.gm.upgrades:AddPlayer(pid,hero)
  for i=0,hero:GetAbilityCount()-1 do
    local talent=hero:GetAbilityByIndex(i)
    if talent and talent:GetAbilityName():find("special_bonus_duality_",1,true)then talent:SetLevel(0)end
  end
  self:MaxAbilities(hero)
  if path~="base" then
    local d=self.gm.upgrades.registry:hero_directions(hero_name)[path]
    local ok=self.gm.upgrades.offers:dev_set_direction(pid,d.id)
    if not ok then return false,"path_failed" end
    self.gm.upgrades:ProcessEvents()
    if self.gm.upgrades.directions.applied[pid]~=d.id then return false,"path_failed" end
  end
  hero:SetIdleAcquire(false)
  local pos=self:Position({x=self.center.x,y=self.center.y-600,z=self.center.z})
  if pos then FindClearSpaceForUnit(hero,pos,true) end
  self:Refresh(hero)
  PlayerResource:SetCameraTarget(pid,hero)
  hero:SetContextThink("rift_lab_camera",function()
    if self.unit==hero then PlayerResource:SetCameraTarget(pid,nil) end
  end,0.2)
  self.gm.upgrades:SendTo(pid,"rift_lab_focus",{entity=hero:entindex()})
  self.gm.upgrades:SendPrivate(pid)
  self.gm.ui:Publish(true)
  Log.info("LAB","selected hero="..hero_name.." path="..path.." rank="..self.rank)
  return true,"ok"
end
function Lab:Clear()
  for _,unit in ipairs(self.gallery) do remove(unit) end
  for _,unit in ipairs(self.targets) do remove(unit) end
  self.gallery,self.targets={},{}
end
function Lab:Gallery(path)
  if not self.enabled or not Policy.PATHS[path] then return false,"not_enabled" end
  for _,unit in ipairs(self.gallery) do remove(unit) end
  self.gallery={}
  local team=PlayerResource:GetTeam(self.owner)
  local points=Policy.gallery(Config.lab,self.center,#self.roster)
  local reserved,failed={},0
  for i,name in ipairs(self.roster) do
    local pos=self:Position(points[i],reserved)
    local u=pos and CreateUnitByName(name,pos,true,nil,nil,team) or nil
    if exists(u) then
      u._rift_lab_display=true
      u:SetRespawnsDisabled(true);u:SetIdleAcquire(false);u:Stop()
      self.gm.upgrades.directions:ApplyKit(u)
      self:MaxAbilities(u)
      local ok=true
      if path~="base" then ok=self.gm.upgrades.directions:ApplyToHero(u,self.gm.upgrades.registry:hero_directions(name)[path]) end
      if ok then
        Mods.add(u,u,nil,"modifier_rift_lab_display",{})
        u:SetRenderColor(path=="physical" and 255 or 175,path=="magical" and 225 or 210, path=="physical" and 165 or 255)
        self.gallery[#self.gallery+1]=u;reserved[#reserved+1]=pos
      else remove(u);failed=failed+1 end
    else failed=failed+1 end
  end
  self.gallery_path=path
  return failed==0,failed==0 and "ok" or "gallery_partial"
end
function Lab:Target(kind)
  if not self.enabled or not Policy.TARGETS[kind] then return false,"invalid_target" end
  local live={};for _,u in ipairs(self.targets) do if exists(u) then live[#live+1]=u end end;self.targets=live
  if #live>=Config.lab.max_targets then return false,"target_limit" end
  local h=PlayerResource:GetSelectedHeroEntity(self.owner)
  if not exists(h) then return false,"no_hero" end
  local reserved={};for _,u in ipairs(live) do reserved[#reserved+1]=u:GetAbsOrigin() end
  local goal=h:GetAbsOrigin()+h:GetForwardVector()*Config.lab.target_distance
  local pos=self:Position(goal,reserved)
  if not pos then return false,"no_space" end
  local team=h:GetTeamNumber()==DOTA_TEAM_BADGUYS and DOTA_TEAM_GOODGUYS or DOTA_TEAM_BADGUYS
  local u=CreateUnitByName("npc_dota_hero_axe",pos,true,nil,nil,team)
  if not exists(u) then return false,"spawn_failed" end
  u._rift_lab_display=true
  u._rift_lab_target=true
  if self.gm.ids then self.gm.ids:on_spawn(u:entindex(),tostring(u)) end
  u:SetRespawnsDisabled(true);u:SetIdleAcquire(false);u:Stop()
  local hp=kind=="mortal" and Config.lab.mortal_health or Config.lab.target_health
  u:SetBaseMaxHealth(hp);u:SetMaxHealth(hp);u:SetHealth(hp)
  for i=0,u:GetAbilityCount()-1 do local a=u:GetAbilityByIndex(i);if a then a:SetLevel(0) end end
  Mods.add(u,u,nil,"modifier_rift_lab_target",{kind=kind})
  u:SetCustomHealthLabel(kind=="immune" and "IMMUNE" or kind=="mortal" and "MORTAL" or "TARGET",120,210,235)
  self.targets[#self.targets+1]=u
  return true,"ok"
end
function Lab:Start(pid)
  if not self:Allowed(pid) then return false,"not_allowed" end
  if self.enabled then return true,"ok" end
  local hero=PlayerResource:GetSelectedHeroEntity(pid)
  local st=self.gm.director.state
  if not exists(hero) or not (st:is("ACTIVE") or st:is("PREPARATION")) then return false,"no_hero" end
  self.owner,self.enabled=pid,true
  if self.gm.scoring then self.gm.scoring.anti_feed_enabled=false end
  self.center=self.gm.map.fallback and {x=0,y=0,z=0} or self.gm.map.center
  self.gm.relic:DevEnd(self.gm:Now())
  if not st:is("ACTIVE") then st:advance("ACTIVE",self.gm:Now()) end
  Log.try(GameRules:GetGameModeEntity(),"GameMode","SetFogOfWarDisabled",true)
  local ok,why=self:Select(hero:GetUnitName(),"base")
  if not ok then return false,why end
  self:Gallery("base")
  self:Target("immortal")
  Log.info("LAB","single-player laboratory enabled; match progression suspended")
  return true,"ok"
end
function Lab:OnKilled(victim,attacker)
  if not exists(victim) or not victim._rift_lab_target or victim._rift_lab_credited then return end
  victim._rift_lab_credited=true
  if not exists(attacker) or not attacker.GetPlayerOwnerID or attacker:GetPlayerOwnerID()~=self.owner then return end
  self.deaths=(self.deaths or 0)+1
  -- Practice kills exercise LC's actual progression without awarding match score.
  require("rift.engine.lc_magic").on_hero_death(self.gm,
    {killer=self.owner,multiplier=1,assists={}},"lab_target_"..self.deaths)
end
function Lab:Request(args)
  local pid=args and args.PlayerID -- engine-populated, never accept a target player
  if pid==nil or not self:Allowed(pid) then return end
  if self.loading then
    self.gm.upgrades:SendTo(pid,"rift_lab_result",{ok=0,reason="loading"})
    return
  end
  local now=GameRules:GetGameTime()
  if self.last_request[pid] and now-self.last_request[pid]<Config.lab.request_interval then return end
  self.last_request[pid]=now
  local valid,why=Policy.validate(args,self.known)
  local ok=false
  if valid then
    local ran,a,b=pcall(function()
      if args.action=="start" then return self:Start(pid) end
      if not self.enabled then return false,"not_enabled" end
      if args.action=="select" then return self:Select(args.hero,args.path)
      elseif args.action=="gallery" then return self:Gallery(args.path)
      elseif args.action=="target" then return self:Target(args.kind)
      elseif args.action=="clear" then self:Clear()
      elseif args.action=="reset" then self:Refresh(PlayerResource:GetSelectedHeroEntity(pid))
        for _,u in ipairs(self.targets) do
          if exists(u) and u:IsAlive() then u:Purge(false,true,false,true,true);u:SetHealth(u:GetMaxHealth()) end
        end
      elseif args.action=="free" then self.free=not self.free
      elseif args.action=="rank" then self.rank=args.rank;return self:Select(self.hero,self.path) end
      return true,"ok"
    end)
    if ran then ok,why=a,b else why="internal_error";Log.error("LAB",a) end
  end
  if why~="loading" then self.gm.upgrades:SendTo(pid,"rift_lab_result",{ok=ok and 1 or 0,reason=why}) end
  self:Publish()
end
function Lab:OnMainSpawn(hero,pid)
  if self.enabled and pid==self.owner then
    self.unit=hero
    self:Refresh(hero)
  end
end
function Lab:Tick()
  if not self.enabled then
    if self.autostart and self.gm.director.state:is("ACTIVE") then
      for pid in pairs(self.gm.players) do if self:Allowed(pid) then self:Start(pid);break end end
    end
    return
  end
  if self.free then
    local h=PlayerResource:GetSelectedHeroEntity(self.owner)
    if exists(h) and h:IsAlive() then
      h:SetMana(h:GetMaxMana())
      for i=0,h:GetAbilityCount()-1 do local a=h:GetAbilityByIndex(i);if a then a:EndCooldown() end end
    end
  end
end
function Lab:Publish()
  local h=self.owner and PlayerResource:GetSelectedHeroEntity(self.owner)
  CustomNetTables:SetTableValue("rift_match","lab",{
    available=self.gm.dev and PlayerResource:GetPlayerCount()==1 and 1 or 0,
    enabled=self.enabled and 1 or 0,owner=self.owner or -1,
    hero=self.hero or "",path=self.path or "base",rank=self.rank,
    free=self.free and 1 or 0,gallery_count=#self.gallery,target_count=#self.targets,
    loading=self.loading and 1 or 0,
    active_entity=exists(h) and h:entindex() or -1,
  })
end
return Lab
