-- Shadow Fiend magical "Requiem of Souls": three delayed Shadowraze rings with a
-- fixed centre, per-ring dedupe, and the debuff-immunity policy. Pure logic.

local R = {}
R.__index = R

-- cfg = HeroBalance.sf.requiem_magical; rank = ultimate rank; center = {x,y}
function R.start(cfg, rank, cast_id, center, now)
  local self = setmetatable({}, R)
  self.cfg, self.rank, self.cast_id = cfg, rank, cast_id
  self.center = { x = center.x, y = center.y }  -- fixed: caster movement ignored
  self.start_time = now
  self.telegraphed, self.erupted = {}, {}
  self.hit = {}        -- ring .. "|" .. victim -> true
  self.feared = {}     -- victim -> true (one immune fear per cast)
  self.cancelled = false
  return self
end

-- Events due now, in order: { kind = "telegraph"|"erupt", ring = i, radius, points }
function R:due(now)
  local out = {}
  if self.cancelled then return out end
  local t = now - self.start_time + 1e-6 -- tolerance for float game time
  for i = 1, #self.cfg.ring_time do
    local at = self.cfg.ring_time[i]
    if not self.telegraphed[i] and t >= at - self.cfg.telegraph_lead then
      self.telegraphed[i] = true
      table.insert(out, { kind = "telegraph", ring = i, radius = self.cfg.ring_radius[i], points = self:points(i) })
    end
    if not self.erupted[i] and t >= at then
      self.erupted[i] = true
      table.insert(out, { kind = "erupt", ring = i, radius = self.cfg.ring_radius[i], points = self:points(i) })
    end
  end
  return out
end

function R:finished() return self.cancelled or self.erupted[#self.cfg.ring_time] == true end

-- Match end clears immediately.
function R:cancel() self.cancelled = true end

-- Evenly spaced eruption centres on ring i.
function R:points(i)
  local n, rad = self.cfg.eruptions_per_ring, self.cfg.ring_radius[i]
  local pts = {}
  for k = 0, n - 1 do
    local a = k / n * 2 * math.pi
    table.insert(pts, { x = self.center.x + rad * math.cos(a), y = self.center.y + rad * math.sin(a) })
  end
  return pts
end

-- victim_key must include the victim life cycle (e.g. "entindex:life").
-- protection: "invulnerable" | "debuff_immune" | "normal" (checked at hit time).
-- Returns { damage = n, fear = seconds } or nil when nothing applies.
function R:resolve_hit(ring, victim_key, protection)
  local k = ring .. "|" .. tostring(victim_key)
  if self.hit[k] then return nil end       -- one packet per ring per victim
  self.hit[k] = true
  if protection == "invulnerable" then return nil end
  if protection == "debuff_immune" then
    if self.feared[victim_key] then return { damage = 0, fear = 0 } end
    self.feared[victim_key] = true
    return { damage = 0, fear = self.cfg.immune_fear[self.rank] }
  end
  return { damage = self.cfg.ring_damage[self.rank], fear = 0 }
end

return R
