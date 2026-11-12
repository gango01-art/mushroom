local Registry = require("rift.core.upgrade_registry")
local Effects = require("rift.core.upgrade_effects")
local F = require("fixtures")

T.case("values_at clamps rank and reads values", function()
  local ups, dirs = F.data("shipped")
  local reg = Registry.new(ups, dirs)
  T.eq(Effects.values_at(reg:get("pa_keen_edge"), 2).attack_damage, 20)
  T.eq(Effects.values_at(reg:get("pa_keen_edge"), 9).attack_damage, 28)
  T.eq(next(Effects.values_at(reg:get("pa_keen_edge"), 0)), nil)
end)

T.case("stat totals sum only stat_bonus upgrades", function()
  local ups, dirs = F.data("shipped")
  local reg = Registry.new(ups, dirs)
  local t = Effects.stat_totals(reg, { pa_shadow_guard = 2, u_iron_skin = 1, u_vitality = 3, pa_static_edge = 2 })
  T.eq(t.armor, 7); T.eq(t.health, 350); T.eq(t.attack_damage, 0)
end)

-- Parses addon_<lang>.txt token keys (simple KV1 "key" "value" lines).
local function loc_keys(lang)
  local keys = {}
  for line in io.lines("game/resource/addon_" .. lang .. ".txt") do
    local k = line:match('^%s*"([^"]+)"%s+"')
    if k then keys[k] = true end
  end
  return keys
end

T.case("shipped data: implemented entries have engine handlers and ru/en localization", function()
  local ups, dirs = F.data("shipped")
  for _, lang in ipairs({ "russian", "english" }) do
    local errs = Registry.new(ups, dirs, { handlers = Effects.HANDLERS, loc = loc_keys(lang) }):validate()
    T.eq(#errs, 0, lang .. ": " .. table.concat(errs, "; "))
  end
end)

T.case("every implemented stat key is supported by the stat modifier", function()
  local ups = F.data("shipped")
  local known = {}
  for _, k in ipairs(Effects.STAT_KEYS) do known[k] = true end
  for _, u in ipairs(ups) do
    if u.status == "implemented" and u.effect_handler == "stat_bonus" then
      for k in pairs(u.values_by_rank) do T.ok(known[k], u.id .. ": unknown stat " .. k) end
    end
  end
end)
