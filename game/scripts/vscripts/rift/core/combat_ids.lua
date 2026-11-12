-- Server ids for casts/sessions/waves/rings/pulses, victim life-cycle keys, and
-- the proc-recursion rule. Pure logic.

local Ids = {}
Ids.__index = Ids

-- Secondary custom damage sources never start other custom effects.
Ids.SECONDARY = {
  sphere = true, raze_bonus = true, ring = true, pulse = true, wave = true, chain = true,
  statue_arrow = true, spirit = true, trap_blast = true, duel_penalty = true,
}

function Ids.new()
  return setmetatable({ seq = 0, life = {}, gen = {}, uid = {} }, Ids)
end

function Ids:next(kind)
  self.seq = self.seq + 1
  return kind .. "#" .. self.seq
end

-- Engine reports every spawn with a unique handle identity (e.g. tostring(handle)).
-- A reused entindex with a new handle starts a new generation.
function Ids:on_spawn(entindex, handle_uid)
  if self.uid[entindex] ~= handle_uid then
    self.uid[entindex] = handle_uid
    self.gen[entindex] = (self.gen[entindex] or 0) + 1
    self.life[entindex] = 1
  end
end

function Ids:on_death(entindex)
  self.life[entindex] = (self.life[entindex] or 1) + 1
end

-- Stable within one life of one entity; changes after death or index reuse.
function Ids:victim_key(entindex)
  return string.format("%d:%d:%d", entindex, self.gen[entindex] or 0, self.life[entindex] or 1)
end

function Ids.may_proc(source_kind)
  return not Ids.SECONDARY[source_kind]
end

return Ids
