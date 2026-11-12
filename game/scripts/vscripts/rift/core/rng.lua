-- Deterministic seeded RNG (Park-Miller minimal standard), pure Lua 5.1.
-- Independent from math.random so tests and server rolls are reproducible.
-- All arithmetic stays below 2^53, exact in doubles.

local Rng = {}
Rng.__index = Rng

local M = 2147483647
local A = 16807

local function norm_seed(seed)
  seed = math.floor(math.abs(tonumber(seed) or 1)) % M
  if seed == 0 then seed = 1 end
  return seed
end

function Rng.new(seed)
  return setmetatable({ state = norm_seed(seed) }, Rng)
end

-- Stable string hash -> seed, for deriving sub-streams (per player, per offer...).
function Rng.hash(...)
  local h = 5381
  for i = 1, select("#", ...) do
    local s = tostring((select(i, ...)))
    for j = 1, #s do h = (h * 33 + s:byte(j)) % M end
    h = (h * 33 + 124) % M
  end
  return norm_seed(h)
end

function Rng.derive(seed, ...)
  return Rng.new(Rng.hash(seed, ...))
end

-- [0, 1)
function Rng:next()
  self.state = (self.state * A) % M
  return (self.state - 1) / (M - 1)
end

-- integer in [1, n]
function Rng:int(n)
  return math.floor(self:next() * n) + 1
end

-- true with probability p (0..1)
function Rng:chance(p)
  return self:next() < p
end

-- keys: ordered list of keys; weights: key -> non-negative weight. Returns key or nil.
function Rng:weighted(keys, weights)
  local total = 0
  for _, k in ipairs(keys) do total = total + math.max(0, weights[k] or 0) end
  if total <= 0 then return nil end
  local r = self:next() * total
  for _, k in ipairs(keys) do
    local w = math.max(0, weights[k] or 0)
    if r < w then return k end
    r = r - w
  end
  return keys[#keys]
end

return Rng
