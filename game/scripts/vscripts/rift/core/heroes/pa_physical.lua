-- Phantom Assassin physical direction "Phantom Execution": pure rules.
-- One spirit = one guaranteed critical physical hit on behalf of PA. The crit
-- multiplier is the native Coup de Grace value of the current ultimate rank; it is
-- never rolled again and never multiplied by item crits (the hit is not an attack).

local Exec = {}

-- native_value: crit_bonus read from the installed ability (percent, 0/nil if unreadable).
function Exec.crit_percent(native_value, rank, fallback)
  if type(native_value) == "number" and native_value > 0 then return native_value end
  rank = math.max(1, math.min(#fallback, rank or 1))
  return fallback[rank]
end

-- Damage before armor (armor is applied by the engine as for any physical damage).
function Exec.hit_damage(attack_damage, crit_percent)
  return math.max(0, attack_damage or 0) * crit_percent / 100
end

-- t: { exists, alive, invulnerable, absorbed }. The spirit hits only a present,
-- living, vulnerable target that did not block the spell.
function Exec.can_hit(t)
  if not t or not t.exists or not t.alive then return false, "no_target" end
  if t.invulnerable then return false, "invulnerable" end
  if t.absorbed then return false, "absorbed" end
  return true
end

return Exec
