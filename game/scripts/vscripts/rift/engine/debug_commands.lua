-- Dev-only console commands (our own, prefixed rift_). Server checks dev mode
-- on every call; in a normal published lobby they do nothing.

local Log = require("rift.engine.log")

local Debug = {}

local function guard(gm)
  if not gm.dev then
    Log.warn("DEV", "command refused: not in dev mode (tools mode or sv_cheats required)")
    return false
  end
  return true
end

function Debug.register(gm)
  local function cmd(name, help, fn)
    Convars:RegisterCommand(name, function(_, ...)
      if not guard(gm) then return end
      local ok, err = pcall(fn, ...)
      if not ok then Log.error("DEV", name .. ": " .. tostring(err)) end
    end, help, FCVAR_CHEAT)
  end

  cmd("rift_status", "Print match state, time and scores", function()
    local st = gm.director.state
    local now = gm:Now()
    Log.info("DEV", string.format("version=%s state=%s elapsed=%.1f remaining=%.1f offset=%.1f map_fallback=%s",
      gm.cfg.VERSION, st.state, st:active_elapsed(now), st:active_remaining(now), gm.clock_offset,
      tostring(gm.map and gm.map.fallback)))
    for _, r in ipairs(gm.scoring:standings()) do
      Log.info("DEV", string.format("  pid=%d score=%d K/D/A=%d/%d/%d streak=%d", r.pid, r.score, r.kills,
        r.deaths, r.assists, r.streak))
    end
  end)

  cmd("rift_skip", "rift_skip <seconds>: advance match clock (logic only)", function(sec)
    local s = tonumber(sec or "60") or 60
    if s <= 0 then return end
    gm.clock_offset = gm.clock_offset + s
    Log.info("DEV", "clock advanced by " .. s .. " s")
  end)

  cmd("rift_addscore", "rift_addscore <pid> <points>", function(pid, pts)
    pid, pts = tonumber(pid), tonumber(pts or "1")
    if not pid or not gm.scoring:get(pid) then Log.warn("DEV", "unknown pid"); return end
    if not gm.director.state:rewards_open() then Log.warn("DEV", "rewards closed in this state"); return end
    gm.scoring:add_score(pid, pts, gm:Now(), "dev")
    gm.ui:Publish(true)
  end)

  cmd("rift_map_check", "Re-run map contract check", function()
    local MapContract = require("rift.engine.map_contract")
    gm.map = MapContract.load(gm.dev)
    Log.info("DEV", "missing=" .. #gm.map.missing .. " fallback=" .. tostring(gm.map.fallback))
  end)

  cmd("rift_kill", "rift_kill <pid>: kill that player's hero (no killer)", function(pid)
    pid = tonumber(pid or "0")
    local h = pid and PlayerResource:GetSelectedHeroEntity(pid)
    if h and h:IsAlive() then h:Kill(nil, nil) end
  end)

  cmd("rift_dump_hero", "rift_dump_hero [pid]: print abilities and their KV (for verifying native values)", function(pid)
    pid = tonumber(pid or "0")
    local h = PlayerResource:GetSelectedHeroEntity(pid)
    if not h then Log.warn("DEV", "no hero for pid " .. tostring(pid)); return end
    Log.info("DEV", "hero=" .. h:GetUnitName() .. " abilities=" .. h:GetAbilityCount())
    local function dump(t, indent, depth)
      if depth > 6 then return end
      local keys = {}
      for k in pairs(t) do table.insert(keys, tostring(k)) end
      table.sort(keys)
      for _, k in ipairs(keys) do
        local v = t[k] ~= nil and t[k] or t[tonumber(k)]
        if type(v) == "table" then
          print(indent .. k .. " {")
          dump(v, indent .. "  ", depth + 1)
          print(indent .. "}")
        else
          print(indent .. k .. " = " .. tostring(v))
        end
      end
    end
    for i = 0, h:GetAbilityCount() - 1 do
      local a = h:GetAbilityByIndex(i)
      if a and not a:IsNull() then
        print(string.format("[RIFT][DUMP] slot=%d name=%s level=%d/%d type=%s", i, a:GetAbilityName(),
          a:GetLevel(), a:GetMaxLevel(), tostring(a:GetAbilityType())))
        local kv = a.GetAbilityKeyValues and a:GetAbilityKeyValues()
        if type(kv) == "table" then dump(kv, "    ", 0) end
      end
    end
  end)

  cmd("rift_verbose", "Toggle verbose debug logging", function()
    Log.verbose = not Log.verbose
    Log.info("DEV", "verbose=" .. tostring(Log.verbose))
  end)
end

return Debug
