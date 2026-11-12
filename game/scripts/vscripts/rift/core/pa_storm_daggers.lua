-- Phantom Assassin magical direction "Storm Daggers": cast context logic.
-- One user cast of Stifling Dagger -> up to 2 different targets. One server roll
-- per cast (only when a second valid target exists). Chain fires only if BOTH
-- daggers of the SAME cast hit two different valid targets. Each target gets the
-- chain damage exactly once. Contexts expire; casts never mix.
-- Pure logic: engine passes target ids (entindex) and validity.

local Rng = require("rift.core.rng")

local Storm = {}
Storm.__index = Storm

Storm.MAX_CONTEXTS_PER_CASTER = 4 -- budget; oldest dropped beyond this

-- values: { chain_chance, chain_damage, cast_context_seconds } for the current rank
function Storm.new(seed)
  local self = setmetatable({}, Storm)
  self.rng = Rng.derive(seed or 1, "pa_storm_daggers")
  self.contexts = {}  -- cast_id -> ctx
  self.seq = 0
  return self
end

-- Values for the current ultimate rank from the balance table (hero_balance.pa.storm_magical).
function Storm.values_at(balance, rank)
  rank = math.max(1, math.min(3, rank or 1))
  return { chain_chance = balance.chain_chance[rank], chain_damage = balance.chain_damage[rank],
           cast_context_seconds = balance.cast_context_seconds }
end

-- Returns cast_id. secondary may be nil (no valid extra target found).
function Storm:begin_cast(caster, primary, secondary, values, now)
  assert(primary ~= nil, "primary target required")
  if secondary == primary then secondary = nil end
  self.seq = self.seq + 1
  local proc = false
  -- force_proc: dev/testing switch only (rift_pa_storm_always); never set in a normal match.
  if secondary ~= nil then proc = self.force_proc or self.rng:chance(values.chain_chance) end
  local ctx = {
    id = self.seq, caster = caster, primary = primary, secondary = secondary,
    proc = proc, damage = values.chain_damage, hits = {}, hit_count = 0,
    failed = false, resolved = false, expires = now + values.cast_context_seconds,
  }
  self.contexts[ctx.id] = ctx
  self:_enforce_budget(caster)
  return ctx.id, proc
end

function Storm:_enforce_budget(caster)
  local ids = {}
  for id, c in pairs(self.contexts) do if c.caster == caster then table.insert(ids, id) end end
  table.sort(ids)
  while #ids > Storm.MAX_CONTEXTS_PER_CASTER do
    self.contexts[table.remove(ids, 1)] = nil
  end
end

-- A dagger of cast_id reached target. valid=false for disjoint/blocked/dead/invalid.
-- Returns chain table { targets = {a, b}, damage } exactly once, or nil.
function Storm:on_hit(cast_id, target, valid, now)
  local c = self.contexts[cast_id]
  if not c or c.resolved then return nil end
  if now > c.expires then self.contexts[cast_id] = nil; return nil end
  if target ~= c.primary and target ~= c.secondary then return nil end -- foreign target: never mix casts
  if c.hits[target] ~= nil then return nil end                           -- duplicate hit event
  c.hits[target] = valid and true or false
  if not valid then c.failed = true end
  c.hit_count = c.hit_count + 1
  local expected = c.secondary and 2 or 1
  if c.hit_count < expected then return nil end
  c.resolved = true
  self.contexts[cast_id] = nil
  if c.failed or not c.secondary or not c.proc then return nil end
  return { cast_id = c.id, caster = c.caster, targets = { c.primary, c.secondary }, damage = c.damage }
end

function Storm:cleanup(now)
  for id, c in pairs(self.contexts) do
    if now > c.expires then self.contexts[id] = nil end
  end
end

function Storm:count()
  local n = 0
  for _ in pairs(self.contexts) do n = n + 1 end
  return n
end

-- Secondary target choice: prefer enemy heroes, then other units, nearest first,
-- within radius of the primary. candidates: { id, x, y, is_hero }, primary_pos {x,y}.
function Storm.pick_secondary(primary_id, primary_pos, candidates, radius)
  local best, best_hero, best_d
  for _, c in ipairs(candidates) do
    if c.id ~= primary_id then
      local dx, dy = c.x - primary_pos.x, c.y - primary_pos.y
      local d = math.sqrt(dx * dx + dy * dy)
      if d <= radius then
        local ch = c.is_hero and true or false
        local better = false
        if not best then better = true
        elseif ch and not best_hero then better = true
        elseif ch == best_hero and (d < best_d or (d == best_d and c.id < best.id)) then better = true end
        if better then best, best_hero, best_d = c, ch, d end
      end
    end
  end
  return best and best.id or nil
end

return Storm
