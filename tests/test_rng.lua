local Rng = require("rift.core.rng")

T.case("same seed -> same sequence; derive is stable", function()
  local a, b = Rng.new(42), Rng.new(42)
  for _ = 1, 100 do T.eq(a:next(), b:next()) end
  T.eq(Rng.derive(7, "x", 1):int(1000), Rng.derive(7, "x", 1):int(1000))
  T.ok(Rng.hash(7, "x", 1) ~= Rng.hash(7, "x", 2), "different streams")
end)

T.case("values in range; chance(0.2) near 20% over 20000 rolls", function()
  local r = Rng.new(123)
  local hits = 0
  for _ = 1, 20000 do
    local v = r:next()
    T.ok(v >= 0 and v < 1, "range")
    if r:chance(0.2) then hits = hits + 1 end
  end
  local rate = hits / 20000
  T.ok(rate > 0.18 and rate < 0.22, "rate " .. rate)
end)

T.case("weighted respects zero weights", function()
  local r = Rng.new(5)
  for _ = 1, 200 do T.eq(r:weighted({ "a", "b" }, { a = 0, b = 3 }), "b") end
  T.eq(r:weighted({ "a" }, { a = 0 }), nil)
end)
