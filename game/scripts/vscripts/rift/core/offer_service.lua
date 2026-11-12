-- Offers: regular upgrade offers on a schedule, and the one-time ultimate
-- direction offer triggered by the first point in the hero's ultimate.
-- Pure, deterministic (seeded), server-authoritative. The engine layer:
--   * calls tick(now, active_elapsed, regular_open) from the thinker,
--   * calls on_ability_learned(...) from the learned-ability event,
--   * forwards client intents to choose(pid_from_engine_context, offer_id, option_id, now),
--   * drains events() and applies effects / pushes UI.

local Rng = require("rift.core.rng")

local Offers = {}
Offers.__index = Offers

Offers.COMPENSATION = "compensation_gold"

function Offers.new(cfg, registry, seed)
  local self = setmetatable({}, Offers)
  self.cfg = cfg
  self.reg = registry
  self.seed = seed or 1
  self.players = {}
  self.offers = {}        -- offer_id -> offer
  self.seq = 0
  self.queue = {}         -- pending events for the engine
  return self
end

function Offers:add_player(pid, hero_id)
  local p = self.players[pid]
  if not p then
    p = { pid = pid, hero = hero_id, build = {}, build_order = {}, direction = nil, direction_id = nil,
          regular_issued = 0, ultimate_offered = false, compensations = 0 }
    self.players[pid] = p
  elseif hero_id and not p.ultimate_offered and next(p.build) == nil then
    p.hero = hero_id
  end
  return p
end

function Offers:player(pid) return self.players[pid] end

local function push(self, ev) table.insert(self.queue, ev) end
function Offers:events()
  local q = self.queue
  self.queue = {}
  return q
end

---------------------------------------------------------------------------
-- Candidate filtering
---------------------------------------------------------------------------
function Offers:is_allowed(p, u)
  if not u or u.type ~= "regular" or u.status ~= "implemented" then return false end
  if u.hero ~= "universal" and u.hero ~= p.hero then return false end
  if (p.build[u.id] or 0) >= u.max_rank then return false end
  if u.required_direction ~= "any" and u.required_direction ~= p.direction then return false end
  for _, pre in ipairs(u.prerequisites or {}) do
    if (p.build[pre] or 0) < 1 then return false end
  end
  if u.exclusive_group then
    for id, rank in pairs(p.build) do
      local o = self.reg:get(id)
      if rank > 0 and o and o.id ~= u.id and o.exclusive_group == u.exclusive_group then return false end
    end
  end
  return true
end

function Offers:candidates(p)
  local out = {}
  for _, u in ipairs(self.reg.upgrades) do
    if self:is_allowed(p, u) then table.insert(out, u) end
  end
  return out
end

function Offers:rarity_weights(active_elapsed)
  for _, ph in ipairs(self.cfg.upgrades.rarity_phases) do
    if active_elapsed < ph.until_seconds then return ph.weights end
  end
  local list = self.cfg.upgrades.rarity_phases
  return list[#list].weights
end

-- Picks up to N distinct options. first_offer -> common only (if any common exists).
function Offers:generate(p, rng, active_elapsed, first_offer)
  local by_rarity = { common = {}, rare = {}, epic = {} }
  for _, u in ipairs(self:candidates(p)) do table.insert(by_rarity[u.rarity], u) end
  local weights = self:rarity_weights(active_elapsed)
  if first_offer and #by_rarity.common > 0 then weights = { common = 1, rare = 0, epic = 0 } end
  local picked = {}
  local keys = { "common", "rare", "epic" }
  for _ = 1, self.cfg.upgrades.options_per_offer do
    local w = {}
    for _, k in ipairs(keys) do w[k] = (#by_rarity[k] > 0) and (weights[k] or 0) or 0 end
    local rarity = rng:weighted(keys, w)
    if not rarity then
      -- requested rarities empty: fall back to any non-empty pool (still no first-offer leak)
      if first_offer and #by_rarity.common == 0 then
        for _, k in ipairs(keys) do w[k] = #by_rarity[k] end
        rarity = rng:weighted(keys, w)
      end
    end
    if not rarity then break end
    local pool = by_rarity[rarity]
    local idx = rng:int(#pool)
    table.insert(picked, pool[idx].id)
    table.remove(pool, idx)
  end
  return picked
end

---------------------------------------------------------------------------
-- Offer creation
---------------------------------------------------------------------------
function Offers:_new_offer(p, otype, options, default_option, now)
  self.seq = self.seq + 1
  local o = {
    id = self.seq, type = otype, owner = p.pid, options = options, default_option = default_option,
    created_at = now, deadline = now + self.cfg.upgrades.offer_seconds, status = "pending",
  }
  self.offers[o.id] = o
  push(self, { kind = "offer_created", pid = p.pid, offer = o })
  return o
end

function Offers:_issue_regular(p, now, active_elapsed)
  p.regular_issued = p.regular_issued + 1
  local rng = Rng.derive(self.seed, "regular", p.pid, p.regular_issued)
  local opts = self:generate(p, rng, active_elapsed, p.regular_issued == 1)
  if #opts == 0 then
    p.compensations = p.compensations + 1
    return self:_new_offer(p, "compensation", { Offers.COMPENSATION }, Offers.COMPENSATION, now)
  end
  local o = self:_new_offer(p, "regular", opts, opts[1], now)
  o.schedule_index = p.regular_issued
  return o
end

-- Called from the thinker. regular_open = false after 18:00 / outside ACTIVE.
function Offers:tick(now, active_elapsed, regular_open)
  if regular_open then
    local sched = self.cfg.upgrades.schedule
    for _, p in pairs(self.players) do
      while p.regular_issued < #sched and sched[p.regular_issued + 1] <= active_elapsed do
        self:_issue_regular(p, now, active_elapsed)
      end
    end
  end
  -- expire in deterministic order (by offer id)
  local ids = {}
  for id, o in pairs(self.offers) do
    if o.status == "pending" and now >= o.deadline then table.insert(ids, id) end
  end
  table.sort(ids)
  for _, id in ipairs(ids) do self:_timeout(self.offers[id], now) end
end

-- source: "player" (real learn) | "dev_simulate_learn" | "dev_set_level" (never offers)
function Offers:on_ability_learned(pid, ability_name, new_level, source, now)
  local p = self.players[pid]
  if not p then return nil, "unknown_player" end
  if source == "dev_set_level" then return nil, "dev_set_level_ignored" end
  if (new_level or 0) < 1 then return nil, "not_learned" end
  local ult = self.reg:ultimate_ability(p.hero)
  if not ult or ability_name ~= ult then return nil, "not_ultimate" end
  if p.direction or p.ultimate_offered then return nil, "already_offered" end
  local dirs = self.reg:hero_directions(p.hero)
  if not dirs or not dirs.physical or not dirs.magical then return nil, "hero_not_supported" end
  p.ultimate_offered = true
  local default = dirs.physical.default_on_timeout and dirs.physical.id or dirs.magical.id
  return self:_new_offer(p, "ultimate_direction", { dirs.physical.id, dirs.magical.id }, default, now)
end

-- The ultimate's new version cannot be used before a direction is confirmed.
function Offers:ultimate_locked(pid)
  local p = self.players[pid]
  return p ~= nil and p.ultimate_offered and p.direction == nil
end

---------------------------------------------------------------------------
-- Resolution
---------------------------------------------------------------------------
function Offers:_apply(o, option, by, now)
  local p = self.players[o.owner]
  local applied
  if o.type == "ultimate_direction" then
    local d = self.reg:direction(option)
    p.direction, p.direction_id = d.direction, d.id
    applied = { kind = "direction", direction = d.direction, direction_id = d.id }
  elseif o.type == "compensation" then
    applied = { kind = "gold", gold = self.cfg.upgrades.exhaust_compensation_gold }
  else
    p.build[option] = (p.build[option] or 0) + 1
    table.insert(p.build_order, option)
    applied = { kind = "upgrade", upgrade_id = option, rank = p.build[option] }
  end
  o.status = "resolved"
  o.resolution = { option = option, by = by, at = now }
  push(self, { kind = "offer_resolved", pid = o.owner, offer = o, applied = applied })
  return applied
end

function Offers:_timeout(o, now)
  if o.status ~= "pending" then return nil end
  local p = self.players[o.owner]
  if o.type == "regular" then
    -- safe fallback: first still-valid option, else compensation
    for _, id in ipairs(o.options) do
      if self:is_allowed(p, self.reg:get(id)) then return self:_apply(o, id, "timeout", now) end
    end
    o.type = "compensation"
    return self:_apply(o, Offers.COMPENSATION, "timeout", now)
  end
  return self:_apply(o, o.default_option, "timeout", now)
end

-- pid MUST come from the engine's trusted callback context, never from payload.
-- Returns ok, reason, applied.
function Offers:choose(pid, offer_id, option_id, now)
  local o = self.offers[tonumber(offer_id) or -1]
  if not o then return false, "unknown_offer" end
  if o.owner ~= pid then return false, "not_owner" end
  if o.status ~= "pending" then return false, "already_resolved" end
  if now >= o.deadline then
    self:_timeout(o, now)
    return false, "expired"
  end
  local found = false
  for _, id in ipairs(o.options) do if id == option_id then found = true end end
  if not found then return false, "invalid_option" end
  local p = self.players[pid]
  if o.type == "regular" and not self:is_allowed(p, self.reg:get(option_id)) then
    return false, "not_allowed"
  end
  if o.type == "ultimate_direction" and p.direction then return false, "already_resolved" end
  return true, "ok", self:_apply(o, option_id, "player", now)
end

-- Offer to show now: ultimate direction has display priority; others keep their own deadline.
function Offers:visible(pid)
  local best
  for _, o in pairs(self.offers) do
    if o.owner == pid and o.status == "pending" then
      if not best then best = o
      else
        local bu, ou = best.type == "ultimate_direction", o.type == "ultimate_direction"
        if (ou and not bu) or (ou == bu and o.id < best.id) then best = o end
      end
    end
  end
  return best
end

-- Private snapshot for one player (reconnect / late panel). Never includes others' offers.
function Offers:snapshot(pid)
  local p = self.players[pid]
  if not p then return nil end
  local pending = {}
  for _, o in pairs(self.offers) do
    if o.owner == pid and o.status == "pending" then table.insert(pending, o) end
  end
  table.sort(pending, function(a, b) return a.id < b.id end)
  local build = {}
  for id, rank in pairs(p.build) do table.insert(build, { id = id, rank = rank }) end
  table.sort(build, function(a, b) return a.id < b.id end)
  local v = self:visible(pid)
  return { pid = pid, direction = p.direction, direction_id = p.direction_id, build = build,
           pending = pending, visible_offer = v and v.id or nil }
end

return Offers
