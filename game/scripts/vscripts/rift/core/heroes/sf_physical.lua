-- Shadow Fiend physical "Requiem of Souls": red spheres and Shadowraze bonus.
-- Pure logic for charges/regen/dedupe. Damage math helpers included.

local S = {}
S.__index = S

-- cfg = HeroBalance.sf.requiem_physical; rank = ultimate rank 1..3
function S.start(cfg, rank, now)
  local self = setmetatable({}, S)
  self.cfg, self.rank = cfg, rank
  self.start_time = now
  self.charges = cfg.spheres
  self.next_regen = nil      -- time the next sphere returns (only while below max)
  self.raze_claimed = {}     -- cast_id .. "|" .. victim -> true
  self.active = true
  return self
end

function S:regen_time() return self.cfg.sphere_regen[self.rank] end

function S:update(now)
  if not self.active then return end
  if now - self.start_time >= self.cfg.duration then
    self.active = false
    self.charges = 0
    self.next_regen = nil
    return
  end
  -- one regen stage restores one sphere; timer runs only while a slot is free
  while self.next_regen and now >= self.next_regen and self.charges < self.cfg.spheres do
    self.charges = self.charges + 1
    if self.charges < self.cfg.spheres then
      self.next_regen = self.next_regen + self:regen_time()
    else
      self.next_regen = nil
    end
  end
end

-- An attack released at a valid enemy combat target. Returns true if a sphere
-- was spent (at most one per attack). Attacks without spheres stay normal.
function S:consume(now, target_valid)
  self:update(now)
  if not self.active or not target_valid or self.charges <= 0 then return false end
  local was_full = self.charges == self.cfg.spheres
  self.charges = self.charges - 1
  if was_full then self.next_regen = now + self:regen_time() end
  return true
end

-- Extra physical damage of a spent sphere: from attack damage WITHOUT crit.
function S:sphere_damage(attack_damage_no_crit)
  return attack_damage_no_crit * self.cfg.sphere_damage_fraction
end

-- Shadowraze bonus: once per (cast_id, victim), only while active.
function S:claim_raze(now, cast_id, victim_key)
  self:update(now)
  if not self.active then return nil end
  local k = tostring(cast_id) .. "|" .. tostring(victim_key)
  if self.raze_claimed[k] then return nil end
  self.raze_claimed[k] = true
  return self.cfg.raze_bonus_fraction[self.rank]
end

return S
