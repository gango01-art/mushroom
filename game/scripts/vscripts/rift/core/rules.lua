-- Small pure rule helpers: respawn time, passive income accumulation, spawn choice.

local Rules = {}

function Rules.respawn_seconds(cfg, active_seconds)
  local r = cfg.respawn
  local t = r.base_seconds + math.floor((active_seconds or 0) / r.step_seconds)
  return math.max(r.min_seconds, math.min(r.max_seconds, t))
end

-- Fractional passive income accumulator, driven by elapsed game time (pause-safe:
-- caller passes delta of server game time, which does not advance while paused).
function Rules.new_accumulator()
  return { gold = 0, xp = 0 }
end

-- Integrate piecewise income exactly across phase boundaries.
function Rules.income_between(phases, first, last, fallback)
  first,last=math.max(0,first or 0),math.max(0,last or 0)
  if last<=first then return 0 end
  if not phases then return (last-first)*(fallback or 0)end
  local total,left=0,0
  for _,p in ipairs(phases)do
    total=total+math.max(0,math.min(last,p.until_seconds)-math.max(first,left))*p.rate
    left=p.until_seconds
  end
  return total
end

-- Returns integer gold, xp to grant now; keeps the remainder.
function Rules.accumulate(acc, cfg, dt, xp_multiplier, active_end)
  if dt <= 0 then return 0, 0 end
  local last=active_end or dt
  acc.gold = acc.gold + Rules.income_between(cfg.economy.passive_gold_phases,last-dt,last,cfg.economy.passive_gold_per_second)
  acc.xp = acc.xp + cfg.economy.passive_xp_per_second * dt * (xp_multiplier or 1)
  local g = math.floor(acc.gold)
  local x = math.floor(acc.xp)
  acc.gold = acc.gold - g
  acc.xp = acc.xp - x
  return g, x
end

local function dist2d(a, b)
  local dx, dy = a.x - b.x, a.y - b.y
  return math.sqrt(dx * dx + dy * dy)
end
Rules.dist2d = dist2d

-- candidates: list of { name, x, y }; enemies: list of {x,y}; recent: name -> last use time.
-- danger(point) optional -> penalty units. Always returns the best candidate (never waits).
-- Returns candidate, score, ideal(bool: min distance >= desired).
function Rules.choose_spawn(cfg, candidates, enemies, recent, now, danger)
  local r = cfg.respawn
  local best, best_score, best_min
  for _, c in ipairs(candidates) do
    local min_d = 1e9
    for _, e in ipairs(enemies) do
      local d = dist2d(c, e)
      if d < min_d then min_d = d end
    end
    local score = math.min(min_d, 1e6)
    local last = recent and recent[c.name]
    if last and now - last < r.recent_use_seconds then score = score - r.recent_use_penalty end
    if danger then score = score - (danger(c) or 0) end
    if not best or score > best_score then best, best_score, best_min = c, score, min_d end
  end
  if not best then return nil end
  return best, best_score, best_min >= r.desired_enemy_distance
end

return Rules
