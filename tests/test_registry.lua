local Registry = require("rift.core.upgrade_registry")
local F = require("fixtures")

T.case("shipped data validates (structure)", function()
  local ups, dirs = F.data("shipped")
  local errs = Registry.new(ups, dirs):validate()
  T.eq(#errs, 0, table.concat(errs, "; "))
end)

T.case("hero disabled while directions are planned", function()
  local ups, dirs = F.data("planned")
  T.ok(not Registry.new(ups, dirs):hero_enabled(F.PA))
  local ups2, dirs2 = F.data()
  T.ok(Registry.new(ups2, dirs2):hero_enabled(F.PA))
end)

T.case("validator: exactly one physical + one magical + one fallback", function()
  local ups, dirs = F.data()
  dirs[2].direction = "physical"
  local errs = Registry.new(ups, dirs):validate()
  T.ok(#errs > 0)
  ups, dirs = F.data()
  dirs[2].default_on_timeout = true
  T.ok(#Registry.new(ups, dirs):validate() > 0, "two fallbacks rejected")
  ups, dirs = F.data()
  table.remove(dirs, 2)
  T.ok(#Registry.new(ups, dirs):validate() > 0, "single direction rejected")
end)

T.case("validator: legacy ids, ranks, prerequisites, handlers, loc", function()
  local ups, dirs = F.data()
  ups[1].id = "pa_legendary_blade"
  T.ok(#Registry.new(ups, dirs):validate() > 0, "legacy id")
  ups, dirs = F.data()
  ups[1].values_by_rank.attack_damage = { 1, 2 }
  T.ok(#Registry.new(ups, dirs):validate() > 0, "rank length")
  ups, dirs = F.data()
  ups[1].prerequisites = { "nope" }
  T.ok(#Registry.new(ups, dirs):validate() > 0, "unknown prereq")
  ups, dirs = F.data()
  T.ok(#Registry.new(ups, dirs, { handlers = {} }):validate() > 0, "missing handlers")
  T.ok(#Registry.new(ups, dirs, { loc = {} }):validate() > 0, "missing loc")
end)
