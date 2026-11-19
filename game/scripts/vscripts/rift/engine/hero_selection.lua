local Log=require("rift.engine.log")
local M={};M.__index=M
local function player(gm,pid)
  local p=PlayerResource:GetPlayer(pid)
  if not p then return nil end
  if gm.teams then
    local own=PlayerResource:GetTeam(pid)
    for _,team in ipairs(gm.teams) do if own==team then return p end end
    return nil
  end
  return p
end
function M.new(gm)
  local self=setmetatable({gm=gm,pending={},selected={},requests={},snapshot=""},M)
  CustomGameEventManager:RegisterListener("rift_pick_hero",function(_,ev)self:Pick(ev)end)
  return self
end
function M:Publish()
  local players,keys={},{}
  for pid=0,DOTA_MAX_TEAM_PLAYERS-1 do
    if player(self.gm,pid) then
      local hero=self.selected[pid] or ""
      local status=hero~="" and "selected" or self.pending[pid] and "loading" or "choosing"
      players[tostring(#keys+1)]={pid=pid,hero=hero,status=status}
      keys[#keys+1]=pid..":"..hero..":"..status
    end
  end
  local snapshot=table.concat(keys,"|")
  if snapshot~=self.snapshot then
    self.snapshot=snapshot
    CustomNetTables:SetTableValue("rift_match","picks",{players=players,max_players=require("rift.core.config").match.max_players})
  end
end
function M:Reply(pid,status,hero)
  local p=PlayerResource:GetPlayer(pid)
  if p then CustomGameEventManager:Send_ServerToPlayer(p,"rift_pick_result",{status=status,hero=hero or ""}) end
end
function M:Pick(ev)
  local pid=ev and ev.PlayerID
  if type(pid)~="number" or not player(self.gm,pid) then return false end
  if GameRules:State_Get()~=DOTA_GAMERULES_STATE_HERO_SELECTION then self:Reply(pid,"closed");return false end
  local hero=ev.hero
  if type(hero)~="string" or not self.gm.upgrades.registry:hero_enabled(hero) then self:Reply(pid,"invalid");return false end
  if self.pending[pid] or self.selected[pid] then return false end
  local now=GameRules:GetGameTime()
  if self.requests[pid] and now-self.requests[pid]<.3 then return false end
  self.requests[pid]=now;self.pending[pid]=hero;self:Reply(pid,"loading",hero)
  self:Publish()
  local function complete()
    if self.pending[pid]~=hero then return end
    self.pending[pid]=nil
    if GameRules:State_Get()~=DOTA_GAMERULES_STATE_HERO_SELECTION then self:Reply(pid,"closed");self:Publish();return end
    local p=PlayerResource:GetPlayer(pid)
    if not p then return end
    -- Installed Tools API: CDOTAPlayerController:SetSelectedHero(string).
    -- Select through the engine so normal spawning, teams and cosmetics remain intact.
    if type(p.SetSelectedHero)~="function" then self:Reply(pid,"error");return end
    local ok,err=pcall(p.SetSelectedHero,p,hero)
    if not ok then Log.error("PICK",err);self:Reply(pid,"error");return end
    self.selected[pid]=hero;self:Reply(pid,"selected",hero)
    self:Publish()
    Log.info("PICK","confirmed pid="..pid.." hero="..hero)
  end
  GameRules:GetGameModeEntity():SetContextThink("rift_pick_timeout_"..pid,function()
    if self.pending[pid]==hero then self.pending[pid]=nil;self:Reply(pid,"error");self:Publish() end
  end,30)
  local ok,err=pcall(PrecacheUnitByNameAsync,hero,complete,pid)
  if not ok then self.pending[pid]=nil;Log.error("PICK",err);self:Reply(pid,"error");return false end
  return true
end
return M
