-- Templar Assassin magical: directed waves (Q/W/E) with per-wave dedupe and
-- intellect scaling snapshotted at release. Spell amp is applied once by the
-- engine damage system (not here).

local W = {}
W.__index = W

function W.new()
  return setmetatable({ seq = 0, waves = {} }, W)
end

-- Returns wave_id, damage (before spell amp and resistances).
function W:release(owner, base, intellect, scaling, now, lifetime)
  self.seq = self.seq + 1
  local dmg = base + (intellect or 0) * scaling
  self.waves[self.seq] = { owner = owner, damage = dmg, hit = {}, expires = now + (lifetime or 2) }
  return self.seq, dmg
end

-- One hit per wave per victim life cycle. Returns damage or nil.
function W:claim(wave_id, victim_key, now)
  local w = self.waves[wave_id]
  if not w or now > w.expires then return nil end
  if w.hit[victim_key] then return nil end
  w.hit[victim_key] = true
  return w.damage
end

function W:cleanup(now)
  for id, w in pairs(self.waves) do if now > w.expires then self.waves[id] = nil end end
end

function W:count()
  local n = 0
  for _ in pairs(self.waves) do n = n + 1 end
  return n
end

-- Full width -> half width for APIs that take a radius.
function W.half_width(full) return full / 2 end

return W
