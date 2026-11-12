local Transfer = require("rift.core.ability_transfer")
local Ids = require("rift.core.combat_ids")

local function to(max, full) return { max_level = max, full_cooldown_at = function() return full end } end

T.case("transfer keeps rank and remaining cooldown, no refund", function()
  local p = Transfer.plan("keep_rank_keep_cooldown", { level = 2, cooldown_remaining = 30 }, to(3, 70))
  T.eq(p.level, 2); T.eq(p.cooldown, 30); T.eq(p.refund_points, 0)
end)

T.case("transfer never resets a used ability and clamps to new full cooldown", function()
  local p = Transfer.plan("keep_rank_keep_cooldown", { level = 1, cooldown_remaining = 90 }, to(3, 24))
  T.eq(p.cooldown, 24)
  p = Transfer.plan("keep_rank_keep_cooldown", { level = 3, cooldown_remaining = 0 }, to(3, 24))
  T.eq(p.cooldown, 0)
end)

T.case("unlearned stays unlearned; level never above new max", function()
  local p = Transfer.plan("keep_rank_keep_cooldown", { level = 0, cooldown_remaining = 5 }, to(4, 10))
  T.eq(p.level, 0); T.eq(p.cooldown, 0)
  p = Transfer.plan("keep_rank_keep_cooldown", { level = 4, cooldown_remaining = 0 }, to(3, 10))
  T.eq(p.level, 3)
end)

T.case("victim keys change after death and entindex reuse", function()
  local ids = Ids.new()
  ids:on_spawn(5, "h1")
  local k1 = ids:victim_key(5)
  ids:on_spawn(5, "h1") -- respawn of same hero entity
  T.eq(ids:victim_key(5), k1)
  ids:on_death(5)
  local k2 = ids:victim_key(5)
  T.ok(k2 ~= k1)
  ids:on_spawn(5, "h2") -- index reused by another entity
  T.ok(ids:victim_key(5) ~= k2 and ids:victim_key(5) ~= k1)
end)

T.case("unique ids; secondary sources cannot proc", function()
  local ids = Ids.new()
  T.ok(ids:next("ring") ~= ids:next("ring"))
  T.ok(not Ids.may_proc("ring")); T.ok(not Ids.may_proc("sphere")); T.ok(not Ids.may_proc("pulse"))
  T.ok(Ids.may_proc("attack")); T.ok(Ids.may_proc("ability"))
end)
