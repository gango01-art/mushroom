-- Engine bridge for upgrades and ultimate directions.
-- Server-authoritative: client sends only intents (offer_id, option_id). The
-- sender PlayerID comes from the engine-provided callback args, never trusted
-- from anything else. Private state is sent addressed to its owner only.

local Config = require("rift.core.config")
local Mods = require("rift.engine.mods")
local Registry = require("rift.core.upgrade_registry")
local Offers = require("rift.core.offer_service")
local Effects = require("rift.core.upgrade_effects")
local Log = require("rift.engine.log")
local DirectionAdapter = require("rift.engine.direction_adapter")

local Bridge = {}
Bridge.__index = Bridge

local MAX_ID_LEN = 64
local MIN_REQUEST_INTERVAL = 0.1

function Bridge.new(gm)
  local self = setmetatable({}, Bridge)
  self.gm = gm
  self.seed = RandomInt(1, 2000000000)
  self.registry = Registry.new(require("rift.data.upgrades"), require("rift.data.ultimate_directions"),
                               { handlers = Effects.HANDLERS })
  for _, e in ipairs(self.registry:validate()) do Log.error("UPGRADES", "data: " .. e) end
  self.offers = Offers.new(Config, self.registry, self.seed)
  self.last_request = {}
  self.directions = DirectionAdapter.new(self)
  Log.info("UPGRADES", "seed=" .. self.seed)

  ListenToGameEvent("dota_player_learned_ability", Dynamic_Wrap(Bridge, "OnLearnedAbility"), self)
  CustomGameEventManager:RegisterListener("rift_offer_choose", function(_, args) self:OnChoose(args) end)
  CustomGameEventManager:RegisterListener("rift_private_request", function(_, args) self:OnPrivateRequest(args) end)
  return self
end

function Bridge:AddPlayer(pid, hero)
  self.offers:add_player(pid, hero:GetUnitName())
  if not hero:HasModifier("modifier_rift_upgrade_stats") then
    Mods.add(hero, hero, nil, "modifier_rift_upgrade_stats", {})
  end
  self:SendPrivate(pid)
end

-- Respawn / reconnect: restore direction state on the hero entity.
function Bridge:EnsureHero(pid, hero)
  if not hero:HasModifier("modifier_rift_upgrade_stats") then
    Mods.add(hero, hero, nil, "modifier_rift_upgrade_stats", {})
  end
  self.directions:Ensure(pid, hero)
end

function Bridge:StatTotals(pid)
  local p = self.offers:player(pid)
  return Effects.stat_totals(self.registry, p and p.build or {})
end

function Bridge:Direction(pid)
  local p = self.offers:player(pid)
  return p and p.direction or nil
end

function Bridge:Tick(now, active_elapsed, regular_open)
  self.offers:tick(now, active_elapsed, regular_open)
  self:ProcessEvents()
end

function Bridge:ProcessEvents()
  local dirty = {}
  for _, ev in ipairs(self.offers:events()) do
    dirty[ev.pid] = true
    if ev.kind == "offer_created" and ev.offer.type == "ultimate_direction" then self.directions:Lock(ev.pid) end
    if ev.kind == "offer_resolved" then self:Apply(ev.pid, ev.applied, ev.offer) end
    if ev.kind == "dev_granted" then self:Apply(ev.pid, ev.applied, nil) end
  end
  for pid in pairs(dirty) do self:SendPrivate(pid) end
end

function Bridge:Apply(pid, applied, offer)
  if not applied then return end
  if applied.kind == "gold" then
    self.gm:Grant(pid, applied.gold, 0)
  elseif applied.kind == "upgrade" then
    local u = self.registry:get(applied.upgrade_id)
    if u and u.effect_handler == "stat_bonus" then
      local hero = PlayerResource:GetSelectedHeroEntity(pid)
      local m = hero and hero:FindModifierByName("modifier_rift_upgrade_stats")
      if m then m:ForceRefresh() end
    end
  elseif applied.kind == "direction" then
    local def = self.registry:direction(applied.direction_id)
    if def then self.directions:Apply(pid, def) end
    Log.info("UPGRADES", "direction " .. tostring(applied.direction_id) .. " pid=" .. pid)
  end
  if offer then
    Log.info("UPGRADES", string.format("pid=%d offer=%d %s -> %s by=%s", pid, offer.id, offer.type,
      tostring(offer.resolution.option), offer.resolution.by))
  else
    Log.info("UPGRADES", string.format("pid=%d dev grant %s rank %s", pid, tostring(applied.upgrade_id),
      tostring(applied.rank)))
  end
  self.gm.ui:Publish(true)
end

function Bridge:OnLearnedAbility(keys)
  local pid = keys.PlayerID
  local name = keys.abilityname
  if pid == nil or name == nil then
    Log.warn("UPGRADES", "learned_ability event without PlayerID/abilityname")
    return
  end
  local hero = PlayerResource:GetSelectedHeroEntity(pid)
  local ability = hero and hero:FindAbilityByName(name)
  local level = ability and ability:GetLevel() or 0
  local o, why = self.offers:on_ability_learned(pid, name, level, "player", self.gm:Now())
  Log.debug("UPGRADES", string.format("learned pid=%d %s lvl=%d -> %s", pid, name, level,
    o and ("offer " .. o.id) or tostring(why)))
  self:ProcessEvents()
end

local function valid_id(v)
  return (type(v) == "string" or type(v) == "number") and #tostring(v) <= MAX_ID_LEN
end

function Bridge:OnChoose(args)
  local pid = args.PlayerID -- set by the engine for client-sent custom events
  if pid == nil or not PlayerResource:IsValidPlayerID(pid) then return end
  local raw = GameRules:GetGameTime()
  if self.last_request[pid] and raw - self.last_request[pid] < MIN_REQUEST_INTERVAL then return end
  self.last_request[pid] = raw
  local ok, reason
  if self.gm.director.state:is("FINISHED") then
    ok, reason = false, "match_finished"
  elseif not valid_id(args.offer_id) or not valid_id(args.option_id) then
    ok, reason = false, "bad_payload"
  else
    ok, reason = self.offers:choose(pid, tonumber(args.offer_id), tostring(args.option_id), self.gm:Now())
  end
  self:SendTo(pid, "rift_offer_result", { offer_id = tonumber(args.offer_id) or -1, ok = ok and 1 or 0,
                                          reason = reason })
  self:ProcessEvents()
  self:SendPrivate(pid)
end

function Bridge:OnPrivateRequest(args)
  local pid = args.PlayerID
  if pid ~= nil and PlayerResource:IsValidPlayerID(pid) then self:SendPrivate(pid) end
end

function Bridge:SendTo(pid, event, payload)
  local player = PlayerResource:GetPlayer(pid)
  if player then CustomGameEventManager:Send_ServerToPlayer(player, event, payload) end
end

-- Arrays are sent with string keys "1".."n" (Panorama receives objects).
local function arr(list)
  local t = {}
  for i, v in ipairs(list) do t[tostring(i)] = v end
  return t
end

function Bridge:OptionView(p, offer, option_id)
  if offer.type == "ultimate_direction" then
    local d = self.registry:direction(option_id)
    return { id = d.id, kind = "direction", direction = d.direction, loc_name = d.loc_name,
             loc_desc = d.loc_desc, icon = d.icon, is_default = (option_id == offer.default_option) and 1 or 0 }
  elseif option_id == Offers.COMPENSATION then
    return { id = option_id, kind = "compensation", loc_name = "rift_up_compensation_gold",
             loc_desc = "rift_up_compensation_gold_desc", icon = "item_bag_of_gold",
             values = { gold = Config.upgrades.exhaust_compensation_gold },
             is_default = 1 }
  end
  local u = self.registry:get(option_id)
  local now_rank = p.build[u.id] or 0
  return { id = u.id, kind = "upgrade", rarity = u.rarity, loc_name = u.loc_name, loc_desc = u.loc_desc,
           icon = u.icon, rank_now = now_rank, rank_next = now_rank + 1, max_rank = u.max_rank,
           required_direction = u.required_direction,
           values = Effects.values_at(u, now_rank + 1),
           is_default = (option_id == offer.default_option) and 1 or 0 }
end

function Bridge:SendPrivate(pid)
  local snap = self.offers:snapshot(pid)
  if not snap then return end
  local p = self.offers:player(pid)
  local now = self.gm:Now()
  local pending = {}
  for _, o in ipairs(snap.pending) do
    local opts = {}
    for _, id in ipairs(o.options) do table.insert(opts, self:OptionView(p, o, id)) end
    table.insert(pending, { id = o.id, type = o.type, remaining = math.max(0, o.deadline - now),
                            options = arr(opts) })
  end
  local build = {}
  for _, b in ipairs(snap.build) do
    local u = self.registry:get(b.id)
    table.insert(build, { id = b.id, rank = b.rank, max_rank = u and u.max_rank or b.rank,
                          loc_name = u and u.loc_name or b.id, icon = u and u.icon or "",
                          values = u and Effects.values_at(u, b.rank) or {} })
  end
  self:SendTo(pid, "rift_private_state", {
    schema = Config.SCHEMA_VERSION,
    direction = snap.direction or "", direction_id = snap.direction_id or "",
    visible_offer = snap.visible_offer or -1,
    pending = arr(pending), build = arr(build),
  })
end

return Bridge
