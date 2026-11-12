-- Engine adapter: wires Dota callbacks to pure core modules.
-- Responsibilities here: engine settings, event listeners, entity handling.
-- Rules live in rift/core/*. Numbers live in rift/core/config.lua.

local Config = require("rift.core.config")
local Scoring = require("rift.core.scoring")
local Director = require("rift.core.match_director")
local Rules = require("rift.core.rules")
local Log = require("rift.engine.log")
local MapContract = require("rift.engine.map_contract")
local UiBridge = require("rift.engine.ui_bridge")
local UpgradeBridge = require("rift.engine.upgrade_bridge")

local GameMode = {}
GameMode.__index = GameMode

local THINK_INTERVAL = 0.25

-- One team per player (FFA). Team constants resolved at runtime.
local function ffa_teams()
  local names = { "DOTA_TEAM_GOODGUYS", "DOTA_TEAM_BADGUYS", "DOTA_TEAM_CUSTOM_1", "DOTA_TEAM_CUSTOM_2",
                  "DOTA_TEAM_CUSTOM_3", "DOTA_TEAM_CUSTOM_4", "DOTA_TEAM_CUSTOM_5", "DOTA_TEAM_CUSTOM_6" }
  local teams = {}
  for _, n in ipairs(names) do
    if _G[n] then table.insert(teams, _G[n]) else Log.warn("BOOT", "missing team constant " .. n) end
  end
  return teams
end

function GameMode.new()
  local self = setmetatable({}, GameMode)
  self.cfg = Config
  self.dev = (IsInToolsMode and IsInToolsMode()) or (GameRules.IsCheatMode and GameRules:IsCheatMode()) or false
  Config.dev.enabled = self.dev
  self.scoring = Scoring.new(Config)
  if self.dev and Config.dev.disable_anti_feed then self.scoring.anti_feed_enabled = false end
  self.director = Director.new(Config, self.scoring)
  self.clock_offset = 0          -- dev time skip (match logic only)
  self.last_raw_time = nil
  self.players = {}              -- pid -> { initialized, acc, team }
  self.spawn_recent = {}
  self.teams = ffa_teams()
  self.ui = UiBridge.new(self)
  self.director.state:on(function(from, to, now) self:OnStateChanged(from, to, now) end)
  return self
end

-- Server game time used for all match rules (does not advance while paused).
function GameMode:Now()
  return GameRules:GetGameTime() + self.clock_offset
end

function GameMode:Activate()
  Log.info("BOOT", "RIFT ARENA " .. Config.VERSION .. " dev=" .. tostring(self.dev))
  self:ConfigureRules()
  self.map = MapContract.load(self.dev)
  self.upgrades = UpgradeBridge.new(self)

  ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(GameMode, "OnGameRulesStateChange"), self)
  ListenToGameEvent("npc_spawned", Dynamic_Wrap(GameMode, "OnNPCSpawned"), self)
  ListenToGameEvent("entity_killed", Dynamic_Wrap(GameMode, "OnEntityKilled"), self)
  ListenToGameEvent("player_connect_full", Dynamic_Wrap(GameMode, "OnPlayerConnectFull"), self)

  local ent = GameRules:GetGameModeEntity()
  ent:SetContextThink("rift_think", function() return self:Think() end, THINK_INTERVAL)

  require("rift.engine.debug_commands").register(self)
  self.director.state:advance("SETUP", self:Now())
  self.ui:Publish(true)
end

function GameMode:ConfigureRules()
  local m = Config.match
  local ent = GameRules:GetGameModeEntity()

  for _, team in ipairs(self.teams) do
    GameRules:SetCustomGameTeamMaxPlayers(team, 1)
  end
  Log.try(GameRules, "GameRules", "SetCustomGameSetupAutoLaunchDelay", m.setup_autolaunch_seconds)
  Log.try(GameRules, "GameRules", "SetHeroSelectionTime", m.hero_selection_seconds)
  Log.try(GameRules, "GameRules", "SetStrategyTime", 0)
  Log.try(GameRules, "GameRules", "SetShowcaseTime", 0)
  Log.try(GameRules, "GameRules", "SetPreGameTime", m.preparation_seconds)
  Log.try(GameRules, "GameRules", "SetPostGameTime", 60)
  Log.try(GameRules, "GameRules", "SetSameHeroSelectionEnabled", true)
  Log.try(GameRules, "GameRules", "SetUseUniversalShopMode", true)
  Log.try(GameRules, "GameRules", "SetStartingGold", 0)   -- start gold set explicitly on first spawn
  Log.try(GameRules, "GameRules", "SetGoldPerTick", 0)    -- passive gold is custom
  Log.try(GameRules, "GameRules", "SetCreepSpawningEnabled", false)

  Log.try(ent, "GameMode", "SetBuybackEnabled", Config.economy.buyback_enabled)
  Log.try(ent, "GameMode", "SetLoseGoldOnDeath", Config.economy.lose_gold_on_death)
  Log.try(ent, "GameMode", "SetUseCustomHeroLevels", false)
  Log.try(ent, "GameMode", "SetFixedRespawnTime", -1)
  Log.try(ent, "GameMode", "SetTopBarTeamValuesVisible", false)
  Log.try(ent, "GameMode", "SetUseDefaultDOTARuneSpawnLogic", false)
  Log.try(ent, "GameMode", "SetModifyGoldFilter", Dynamic_Wrap(GameMode, "FilterGold"), self)
  Log.try(ent, "GameMode", "SetModifyExperienceFilter", Dynamic_Wrap(GameMode, "FilterXP"), self)

  -- Disable runes explicitly (design: no runes in alpha).
  for _, n in ipairs({ "DOTA_RUNE_DOUBLEDAMAGE", "DOTA_RUNE_HASTE", "DOTA_RUNE_ILLUSION", "DOTA_RUNE_INVISIBILITY",
                       "DOTA_RUNE_REGENERATION", "DOTA_RUNE_BOUNTY", "DOTA_RUNE_ARCANE", "DOTA_RUNE_WATER",
                       "DOTA_RUNE_XP", "DOTA_RUNE_SHIELD" }) do
    if _G[n] then Log.try(ent, "GameMode", "SetRuneEnabled", _G[n], false) end
  end

  -- Standard kill/creep/tick rewards are blocked: all match rewards are custom.
  self.blocked_gold = {}
  for _, n in ipairs({ "DOTA_ModifyGold_HeroKill", "DOTA_ModifyGold_CreepKill", "DOTA_ModifyGold_NeutralKill",
                       "DOTA_ModifyGold_RoshanKill", "DOTA_ModifyGold_Building", "DOTA_ModifyGold_CourierKill",
                       "DOTA_ModifyGold_GameTick", "DOTA_ModifyGold_BountyRune", "DOTA_ModifyGold_Death",
                       "DOTA_ModifyGold_SharedGold", "DOTA_ModifyGold_Unknown_Kill" }) do
    if _G[n] ~= nil then self.blocked_gold[_G[n]] = n end
  end
  self.blocked_xp = {}
  for _, n in ipairs({ "DOTA_ModifyXP_HeroKill", "DOTA_ModifyXP_CreepKill", "DOTA_ModifyXP_RoshanKill",
                       "DOTA_ModifyXP_Outpost" }) do
    if _G[n] ~= nil then self.blocked_xp[_G[n]] = n end
  end
end

function GameMode:FilterGold(ev)
  if self.granting then return true end
  if self.blocked_gold[ev.reason_const] then return false end
  return true
end

function GameMode:FilterXP(ev)
  if self.granting then return true end
  if self.blocked_xp[ev.reason_const] then return false end
  return true
end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
function GameMode:OnGameRulesStateChange()
  local s = GameRules:State_Get()
  local now = self:Now()
  local st = self.director.state
  if s == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
    st:advance("SETUP", now)
    self:AssignTeams()
  elseif s == DOTA_GAMERULES_STATE_HERO_SELECTION then
    self:AssignTeams()
    st:advance("HERO_SELECTION", now)
  elseif s == DOTA_GAMERULES_STATE_PRE_GAME then
    st:advance("PREPARATION", now)
  elseif s == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    st:advance("ACTIVE", now)
  end
end

function GameMode:OnStateChanged(from, to, now)
  Log.info("STATE", from .. " -> " .. to .. " t=" .. string.format("%.1f", now))
  if to == "FINISHED" then self:OnFinished() end
  self.ui:Publish(true)
end

function GameMode:OnFinished()
  local r = self.director.state.result or {}
  Log.info("STATE", "winner=" .. tostring(r.winner) .. " reason=" .. tostring(r.reason))
  self.ui:PublishResult()
  local team = r.winner ~= nil and PlayerResource:GetTeam(r.winner) or nil
  -- Small delay so the result net table reaches clients before the post-game screen.
  GameRules:GetGameModeEntity():SetContextThink("rift_finish", function()
    if team then GameRules:SetGameWinner(team) else GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS) end
    return nil
  end, 3)
end

function GameMode:AssignTeams()
  local used = {}
  for pid = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
    if PlayerResource:IsValidPlayerID(pid) then
      local t = PlayerResource:GetCustomTeamAssignment(pid)
      if t and t ~= DOTA_TEAM_NOTEAM then used[t] = true end
    end
  end
  for pid = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
    if PlayerResource:IsValidPlayerID(pid) then
      local t = PlayerResource:GetCustomTeamAssignment(pid)
      if not t or t == DOTA_TEAM_NOTEAM then
        for _, team in ipairs(self.teams) do
          if not used[team] then
            PlayerResource:SetCustomTeamAssignment(pid, team)
            used[team] = true
            Log.info("TEAM", "player " .. pid .. " -> team " .. team)
            break
          end
        end
      end
    end
  end
end

function GameMode:OnPlayerConnectFull(keys)
  self:AssignTeams()
  self.ui:Publish(true)
end

---------------------------------------------------------------------------
-- Heroes
---------------------------------------------------------------------------
function GameMode:PlayerState(pid)
  local p = self.players[pid]
  if not p then
    p = { initialized = false, acc = Rules.new_accumulator() }
    self.players[pid] = p
    self.scoring:add_player(pid)
  end
  return p
end

local function is_main_hero(unit)
  if not unit or unit:IsNull() or not unit.IsRealHero or not unit:IsRealHero() then return false end
  if unit.IsTempestDouble and unit:IsTempestDouble() then return false end
  if unit.IsClone and unit:IsClone() then return false end
  local pid = unit:GetPlayerOwnerID()
  if pid == nil or pid < 0 then return false end
  return PlayerResource:GetSelectedHeroEntity(pid) == unit
end

function GameMode:OnNPCSpawned(keys)
  local unit = EntIndexToHScript(keys.entindex)
  if not unit or unit:IsNull() or not unit.IsRealHero or not unit:IsRealHero() then return end
  -- Selected hero entity may not be registered on the very first frame; defer.
  unit:SetContextThink("rift_spawned", function()
    if not is_main_hero(unit) then return nil end
    local pid = unit:GetPlayerOwnerID()
    local p = self:PlayerState(pid)
    if not p.initialized then
      p.initialized = true
      self:InitHero(unit, pid)
    else
      self:PlaceAtSpawn(unit, pid)
    end
    unit:AddNewModifier(unit, nil, "modifier_rift_spawn_shield", { duration = self.cfg.respawn.shield_seconds })
    return nil
  end, 0)
end

function GameMode:InitHero(hero, pid)
  local e = self.cfg.economy
  while hero:GetLevel() < e.start_level do hero:HeroLevelUp(false) end
  self.granting = true
  PlayerResource:SetGold(pid, 0, false)
  PlayerResource:SetGold(pid, e.start_gold, true)
  self.granting = false
  hero:AddNewModifier(hero, nil, "modifier_rift_damage_tracker", {})
  self.upgrades:AddPlayer(pid, hero)
  self:PlaceAtSpawn(hero, pid)
  Log.info("HERO", string.format("init pid=%d hero=%s level=%d", pid, hero:GetUnitName(), hero:GetLevel()))
  self.ui:Publish(true)
end

function GameMode:LiveEnemyPositions(pid)
  local list = {}
  for opid, _ in pairs(self.players) do
    if opid ~= pid then
      local h = PlayerResource:GetSelectedHeroEntity(opid)
      if h and not h:IsNull() and h:IsAlive() then
        local o = h:GetAbsOrigin()
        table.insert(list, { x = o.x, y = o.y })
      end
    end
  end
  return list
end

function GameMode:PlaceAtSpawn(hero, pid)
  local now = self:Now()
  local c, _, ideal = Rules.choose_spawn(self.cfg, self.map.spawns, self:LiveEnemyPositions(pid), self.spawn_recent, now)
  if not c then return end
  self.spawn_recent[c.name] = now
  local pos = GetGroundPosition(Vector(c.x, c.y, c.z or 0), hero)
  FindClearSpaceForUnit(hero, pos, true)
  hero:Stop()
  PlayerResource:SetCameraTarget(pid, hero)
  hero:SetContextThink("rift_cam", function() PlayerResource:SetCameraTarget(pid, nil); return nil end, 0.2)
  Log.debug("SPAWN", string.format("pid=%d at %s ideal=%s", pid, c.name, tostring(ideal)))
end

---------------------------------------------------------------------------
-- Combat
---------------------------------------------------------------------------
local function owner_pid(unit)
  if not unit or unit:IsNull() or not unit.GetPlayerOwnerID then return nil end
  local pid = unit:GetPlayerOwnerID()
  if pid == nil or pid < 0 then return nil end
  return pid
end

function GameMode:OnHeroDamaged(victim, attacker, damage)
  if not self.director.state:rewards_open() then return end
  if not is_main_hero(victim) then return end
  local vpid, apid = owner_pid(victim), owner_pid(attacker)
  if not vpid or not apid or vpid == apid then return end
  self.scoring:record_damage(vpid, apid, damage, self:Now())
end

function GameMode:Grant(pid, gold, xp)
  local hero = PlayerResource:GetSelectedHeroEntity(pid)
  self.granting = true
  if gold and gold > 0 then PlayerResource:ModifyGold(pid, gold, true, DOTA_ModifyGold_Unspecified) end
  if xp and xp > 0 and hero and not hero:IsNull() then
    hero:AddExperience(xp, DOTA_ModifyXP_Unspecified, false, true)
  end
  self.granting = false
end

function GameMode:OnEntityKilled(keys)
  local victim = EntIndexToHScript(keys.entindex_killed)
  if not is_main_hero(victim) then return end
  if victim.IsReincarnating and victim:IsReincarnating() then return end
  local now = self:Now()
  local vpid = owner_pid(victim)
  local attacker = keys.entindex_attacker and EntIndexToHScript(keys.entindex_attacker) or nil
  local kpid = owner_pid(attacker)

  victim:SetTimeUntilRespawn(Rules.respawn_seconds(self.cfg, self.director.state:active_elapsed(now)))

  if not self.director.state:rewards_open() then return end
  self:PlayerState(vpid)
  local token = tostring(keys.entindex_killed) .. "@" .. string.format("%.3f", GameRules:GetGameTime())
  local r, why = self.scoring:on_hero_death(vpid, kpid, now, victim:GetMaxHealth(), token)
  if not r then Log.debug("KILL", "ignored: " .. tostring(why)); return end
  if r.killer then self:Grant(r.killer, r.kill_gold, r.kill_xp) end
  for _, a in ipairs(r.assists) do self:Grant(a.pid, a.gold, a.xp) end
  Log.info("KILL", string.format("victim=%d killer=%s score=%s repeat=%s assists=%d reason=%s",
    vpid, tostring(r.killer), tostring(r.kill_score), tostring(r.repeat_n), #r.assists, r.reason))
  self.ui:Publish(true)
end

---------------------------------------------------------------------------
-- Think
---------------------------------------------------------------------------
function GameMode:Think()
  local raw = GameRules:GetGameTime()
  local dt = self.last_raw_time and (raw - self.last_raw_time) or 0
  self.last_raw_time = raw
  local st = self.director.state
  if st:rewards_open() and dt > 0 then
    for pid, p in pairs(self.players) do
      if PlayerResource:IsValidPlayerID(pid) then
        local g, x = Rules.accumulate(p.acc, self.cfg, dt)
        self:Grant(pid, g, x)
      end
    end
  end
  local now = self:Now()
  if st:rewards_open() then
    -- regular offers only during ACTIVE (not after 18:00 / in overtime); expiry keeps running
    self.upgrades:Tick(now, st:active_elapsed(now), st:is("ACTIVE"))
  end
  self.director:tick(now)
  self.ui:Publish(false)
  if st:is("FINISHED") then return nil end
  return THINK_INTERVAL
end

return GameMode
