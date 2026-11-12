-- Structured, bounded console logging. Prefix makes grep in console.log easy.
local Log = {}
Log.verbose = false
local count, LIMIT = 0, 2000 -- avoid flooding the console in long matches

local function out(level, tag, msg)
  count = count + 1
  if count > LIMIT and level ~= "ERROR" then return end
  print(string.format("[RIFT][%s][%s] %s", level, tag, tostring(msg)))
end

function Log.info(tag, msg) out("INFO", tag, msg) end
function Log.warn(tag, msg) out("WARN", tag, msg) end
function Log.error(tag, msg) out("ERROR", tag, msg) end
function Log.debug(tag, msg) if Log.verbose then out("DEBUG", tag, msg) end end

-- Call obj:method(...) only if it exists; logs once per missing API so wrong API
-- assumptions show up in the console instead of crashing the bootstrap.
local missing = {}
function Log.try(obj, objname, method, ...)
  if obj == nil or type(obj[method]) ~= "function" then
    local key = objname .. ":" .. method
    if not missing[key] then
      missing[key] = true
      out("WARN", "API", "missing " .. key .. " (skipped)")
    end
    return nil
  end
  local ok, res = pcall(obj[method], obj, ...)
  if not ok then out("ERROR", "API", objname .. ":" .. method .. " failed: " .. tostring(res)) end
  return res
end

return Log
