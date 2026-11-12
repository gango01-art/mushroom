-- Minimal test runner for pure logic. Run from repo root:  lua5.1 tests/run.lua
package.path = "game/scripts/vscripts/?.lua;tests/?.lua;" .. package.path

local T = { passed = 0, failed = 0, current = "" }
_G.T = T

function T.eq(a, b, msg)
  if a ~= b then
    error(string.format("%s: expected %s, got %s", msg or "eq", tostring(b), tostring(a)), 2)
  end
end
function T.ok(v, msg) if not v then error((msg or "expected truthy"), 2) end end

local function deepcopy(t)
  if type(t) ~= "table" then return t end
  local r = {}
  for k, v in pairs(t) do r[k] = deepcopy(v) end
  return r
end
function T.config()
  package.loaded["rift.core.config"] = nil
  return deepcopy(require("rift.core.config"))
end

function T.case(name, fn)
  local ok, err = pcall(fn)
  if ok then T.passed = T.passed + 1
  else
    T.failed = T.failed + 1
    print("FAIL  " .. T.current .. " :: " .. name .. "\n      " .. tostring(err))
  end
end

local suites = { "test_match_state", "test_scoring", "test_director", "test_rules",
                 "test_rng", "test_registry", "test_offers", "test_storm" }
for _, s in ipairs(suites) do
  T.current = s
  require(s)
end
print(string.format("%d passed, %d failed", T.passed, T.failed))
os.exit(T.failed == 0 and 0 or 1)
