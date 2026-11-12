-- Templar Assassin physical "Psionic Crystal": durability, pulses, dedupe and
-- damage from the Psi Blades coefficient (read from real E data by the engine).

local C = {}
C.__index = C

local seq = 0

-- cfg = HeroBalance.ta.crystal_physical; rank = ultimate rank 1..3
function C.new(cfg, rank, now)
  seq = seq + 1
  local self = setmetatable({}, C)
  self.id, self.cfg, self.rank = seq, cfg, rank
  self.start_time = now
  self.durability = cfg.durability
  self.pulse_seq = 0
  self.hits = {}       -- pulse_id .. "|" .. victim -> true
  self.alive = true
  return self
end

function C:radius() return self.cfg.radius[self.rank] end
function C:expired(now) return now - self.start_time >= self.cfg.lifetime end

-- attacker: "owner" (TA main hero) | "enemy" | "other" (illusions/summons: ignored).
-- Returns { pulse_id = n or nil, destroyed = bool }.
function C:on_attacked(attacker)
  if not self.alive then return { destroyed = true } end
  if attacker == "other" then return { destroyed = false } end
  local r = {}
  if attacker == "owner" then
    self.pulse_seq = self.pulse_seq + 1
    r.pulse_id = self.id * 1000 + self.pulse_seq  -- pulse first, then durability
  end
  self.durability = self.durability - 1
  if self.durability <= 0 then self.alive = false end
  r.destroyed = not self.alive
  return r
end

-- Timer expiry / cleanup: no pulse.
function C:remove() self.alive = false end

-- One hit per (pulse, victim life cycle).
function C:claim(pulse_id, victim_key)
  local k = tostring(pulse_id) .. "|" .. tostring(victim_key)
  if self.hits[k] then return false end
  self.hits[k] = true
  return true
end

-- source_hit: full attacking-hit damage of TA (with Refraction/Meld/crit spent on
-- THIS attack), independent of crystal HP/armor. coefficient: from Psi Blades.
function C.pulse_damage(source_hit, psi_coefficient)
  return source_hit * psi_coefficient
end

return C
