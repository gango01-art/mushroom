-- Single path for adding our Lua modifiers: reports a failed attach once per
-- modifier name instead of failing silently (see KNOWN_ISSUES 13).
local Log = require("rift.engine.log")

local Mods = {}
local reported = {}

function Mods.add(unit, caster, ability, name, kv)
  if not unit or unit:IsNull() then return nil end
  local m = unit:AddNewModifier(caster, ability, name, kv or {})
  if not m or not unit:HasModifier(name) then
    if not reported[name] then
      reported[name] = true
      Log.error("MODS", "failed to attach " .. name .. " (unknown modifier type? run rift_modtest)")
    end
    return nil
  end
  return m
end

return Mods
