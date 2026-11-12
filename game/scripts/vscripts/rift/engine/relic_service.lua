-- Engine side of the Heart of the Rift: positions, pickup, reveal, drop/reset,
-- particles and HUD state. Rules live in rift/core/relic_event.lua.

local Config = require("rift.core.config")
local Mods = require("rift.engine.mods")
local Relic = require("rift.core.relic_event")
local Log = require("rift.engine.log")

local Service = {}
Service.__index = Service

function Service.new(gm, seed)
  local self = setmetatable({}, Service)
  self.gm = gm
  self.cfg = Config.relic
  self.points = gm.map.relics
  self.relic = Relic.new(self.cfg, seed, #self.points)
  self.ground_pos = nil
  self.ground_fx = nil
  self.next_reveal = 0
  self.last_valid_carrier_pos = nil
  return self
end

local function vec(p) return GetGroundPosition(Vector(p.x, p.y, p.z or 0), nil) end

function Service:_fx_ground(pos)
  self:_fx_clear()
  if self.cfg.particle_ground and self.cfg.particle_ground ~= "" then
    self.ground_fx = ParticleManager:CreateParticle(self.cfg.particle_ground, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(self.ground_fx, 0, pos)
  end
end

function Service:_fx_clear()
  if self.ground_fx then
    ParticleManager:DestroyParticle(self.ground_fx, false)
    ParticleManager:ReleaseParticleIndex(self.ground_fx)
    self.ground_fx = nil
  end
end

function Service:_set_ground(pos)
  self.ground_pos = pos
  self:_fx_ground(pos)
  if MinimapEvent then
    for _, team in ipairs(self.gm.teams) do
      pcall(MinimapEvent, team, GameRules:GetGameModeEntity(), pos.x, pos.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 3)
    end
  end
end

function Service:_nearest_point(pos)
  local best, bd
  for _, p in ipairs(self.points) do
    local d = (Vector(p.x, p.y, 0) - Vector(pos.x, pos.y, 0)):Length2D()
    if not bd or d < bd then best, bd = p, d end
  end
  return best and vec(best) or pos
end

function Service:_valid_drop(pos)
  if not pos then return false end
  local b1, b2 = self.gm.map.bounds_min, self.gm.map.bounds_max
  if b1 and b2 and (pos.x < b1.x or pos.y < b1.y or pos.x > b2.x or pos.y > b2.y) then return false end
  if GridNav and GridNav.IsTraversable and not GridNav:IsTraversable(pos) then return false end
  return true
end

function Service:_carrier_hero()
  local pid = self.relic:carrier()
  return pid and PlayerResource:GetSelectedHeroEntity(pid) or nil, pid
end

function Service:_drop(now, pos, why)
  local hero = self:_carrier_hero()
  local ok, out = self.relic:drop(now)
  if not ok then return end
  if hero and not hero:IsNull() then hero:RemoveModifierByName("modifier_rift_relic_carrier") end
  local target = self:_valid_drop(pos) and pos or self:_nearest_point(pos or self.last_valid_carrier_pos or Vector(0, 0, 0))
  self:_set_ground(target)
  Log.info("RELIC", "dropped (" .. why .. ")")
  self:_handle(out, now)
end

function Service:_handle(events, now)
  for _, e in ipairs(events) do
    if e.kind == "warning" then
      local p = self.points[e.point]
      if p then self:_fx_ground(vec(p)) end
      Log.info("RELIC", "warning point=" .. e.point .. " in " .. e.spawn_in .. " s")
    elseif e.kind == "spawn" then
      self:_set_ground(vec(self.points[e.point]))
      Log.info("RELIC", "spawn point=" .. e.point)
    elseif e.kind == "score" then
      self.gm.scoring:add_score(e.pid, e.points, now, "relic")
      self.gm.ui:Publish(true)
    elseif e.kind == "ended" or e.kind == "cleared" then
      local hero = self:_carrier_hero()
      if hero and not hero:IsNull() then hero:RemoveModifierByName("modifier_rift_relic_carrier") end
      self:_fx_clear()
      self.ground_pos = nil
      Log.info("RELIC", e.kind .. " " .. tostring(e.reason or ""))
    end
  end
end

-- Called from the main thinker every tick.
function Service:Tick(now, active_elapsed, allowed)
  self:_handle(self.relic:tick(now, active_elapsed, allowed), now)
  local st = self.relic.state
  if st == "ground" and self.ground_pos then
    self:_try_pickup(now)
  elseif st == "carried" then
    local hero, pid = self:_carrier_hero()
    if not hero or hero:IsNull() or not hero:IsAlive() then
      self:_drop(now, self.last_valid_carrier_pos, "carrier_invalid")
    elseif PlayerResource:GetConnectionState(pid) ~= DOTA_CONNECTION_STATE_CONNECTED then
      self:_drop(now, self:_nearest_point(hero:GetAbsOrigin()), "disconnect")
    elseif hero.IsOutOfGame and hero:IsOutOfGame() then
      self:_drop(now, self.last_valid_carrier_pos, "out_of_game")
    else
      local pos = hero:GetAbsOrigin()
      if self:_valid_drop(pos) then self.last_valid_carrier_pos = pos
      else self:_drop(now, self:_nearest_point(pos), "invalid_area") end
      if now >= self.next_reveal and self.relic.state == "carried" then
        self.next_reveal = now + self.cfg.reveal_interval
        for _, team in ipairs(self.gm.teams) do
          AddFOWViewer(team, pos, self.cfg.reveal_radius, self.cfg.reveal_interval + 0.1, false)
        end
      end
    end
  end
end

function Service:_try_pickup(now)
  -- Deterministic atomic choice: nearest alive main hero, ties by player id.
  local best, bd
  for pid in pairs(self.gm.players) do
    local h = PlayerResource:GetSelectedHeroEntity(pid)
    if h and not h:IsNull() and h:IsAlive() and not (h.IsIllusion and h:IsIllusion())
       and PlayerResource:GetConnectionState(pid) == DOTA_CONNECTION_STATE_CONNECTED then
      local d = (h:GetAbsOrigin() - self.ground_pos):Length2D()
      if d <= self.cfg.pickup_radius and (not bd or d < bd or (d == bd and pid < best)) then best, bd = pid, d end
    end
  end
  if best and self.relic:pickup(best, now) then
    local h = PlayerResource:GetSelectedHeroEntity(best)
    Mods.add(h, h, nil, "modifier_rift_relic_carrier",
      { slow = self.cfg.carrier_move_slow_pct, particle = self.cfg.particle_carrier })
    self:_fx_clear()
    self.ground_pos = nil
    Log.info("RELIC", "picked up by pid=" .. best)
    self.gm.ui:Publish(true)
  end
end

function Service:DevSpawn(now)
  local ev = self.relic:dev_spawn(now)
  if ev then self:_handle(ev, now) end
  return ev ~= nil
end

function Service:DevEnd(now)
  local hero = self:_carrier_hero()
  self:_handle(self.relic:dev_end(), now)
  if hero and not hero:IsNull() then hero:RemoveModifierByName("modifier_rift_relic_carrier") end
end

-- Forced safe drop (e.g. the carrier becomes invulnerable: LC throne).
function Service:ForceDrop(pid, pos, now, why)
  if self.relic:carrier() == pid then self:_drop(now, pos, why or "forced") end
end

-- Carrier death: drop at the death position (validated).
function Service:OnHeroDied(pid, pos, now)
  if self.relic:carrier() == pid then self:_drop(now, pos, "death") end
end

function Service:View(now, active_elapsed)
  local v = self.relic:view(now, active_elapsed)
  local p = v.point > 0 and self.points[v.point] or nil
  v.x, v.y = p and p.x or 0, p and p.y or 0
  if self.ground_pos then v.x, v.y = self.ground_pos.x, self.ground_pos.y end
  return v
end

return Service
