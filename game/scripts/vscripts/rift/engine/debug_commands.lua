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

  cmd("rift_give_upgrade", "rift_give_upgrade <pid> <upgrade_id>: grant a valid upgrade (dev)", function(pid, id)
    pid = tonumber(pid or "0")
    local ok, why = gm.upgrades.offers:dev_grant(pid, tostring(id), gm:Now())
    Log.info("DEV", "give_upgrade " .. tostring(id) .. ": " .. tostring(why))
    gm.upgrades:ProcessEvents()
  end)

  cmd("rift_offer_now", "rift_offer_now [pid]: issue an extra regular offer now (dev)", function(pid)
    pid = tonumber(pid or "0")
    local st = gm.director.state
    local o = gm.upgrades.offers:dev_issue_regular(pid, gm:Now(), st:active_elapsed(gm:Now()))
    Log.info("DEV", "offer_now -> " .. tostring(o and o.id))
    gm.upgrades:ProcessEvents()
  end)

  cmd("rift_learn_ult", "rift_learn_ult [pid]: simulate a real first learn of the ultimate (dev)", function(pid)
    pid = tonumber(pid or "0")
    local p = gm.upgrades.offers:player(pid)
    if not p then Log.warn("DEV", "unknown pid"); return end
    local ult = gm.upgrades.registry:ultimate_ability(p.hero)
    local o, why = gm.upgrades.offers:on_ability_learned(pid, ult, 1, "dev_simulate_learn", gm:Now())
    Log.info("DEV", "learn_ult -> " .. tostring(o and ("offer " .. o.id) or why))
    gm.upgrades:ProcessEvents()
  end)

  cmd("rift_upgrades", "rift_upgrades [pid]: print build, direction and pending offers", function(pid)
    pid = tonumber(pid or "0")
    local snap = gm.upgrades.offers:snapshot(pid)
    if not snap then Log.warn("DEV", "unknown pid"); return end
    Log.info("DEV", "seed=" .. gm.upgrades.seed .. " direction=" .. tostring(snap.direction_id))
    for _, b in ipairs(snap.build) do Log.info("DEV", "  " .. b.id .. " rank " .. b.rank) end
    for _, o in ipairs(snap.pending) do
      Log.info("DEV", string.format("  offer %d %s [%s] left=%.1f", o.id, o.type, table.concat(o.options, ","),
        o.deadline - gm:Now()))
    end
  end)

  cmd("rift_dump_ability", "rift_dump_ability <ability_name> [pid]: temporarily add an ability to the hero, print its KV, remove it", function(name, pid)
    pid = tonumber(pid or "0")
    local h = PlayerResource:GetSelectedHeroEntity(pid)
    if not h or not name then Log.warn("DEV", "usage: rift_dump_ability <ability_name> [pid]"); return end
    local existed = h:FindAbilityByName(name) ~= nil
    local a = h:FindAbilityByName(name) or h:AddAbility(name)
    if not a then Log.warn("DEV", "ability not found in this client: " .. tostring(name)); return end
    print(string.format("[RIFT][DUMP] ability=%s max_level=%d type=%s behavior=%s", name, a:GetMaxLevel(),
      tostring(a:GetAbilityType()), tostring(a:GetBehavior())))
    local kv = a.GetAbilityKeyValues and a:GetAbilityKeyValues()
    local function dump(t, indent, depth)
      if depth > 6 then return end
      for k, v in pairs(t) do
        if type(v) == "table" then print(indent .. tostring(k) .. " {"); dump(v, indent .. "  ", depth + 1); print(indent .. "}")
        else print(indent .. tostring(k) .. " = " .. tostring(v)) end
      end
    end
    if type(kv) == "table" then dump(kv, "    ", 0) else Log.warn("DEV", "GetAbilityKeyValues unavailable") end
    if not existed then h:RemoveAbility(name) end
  end)

  cmd("rift_probe_attacks", "rift_probe_attacks [pid]: toggle attack/damage event logging on the hero (dev)", function(pid)
    pid = tonumber(pid or "0")
    local h = PlayerResource:GetSelectedHeroEntity(pid)
    if not h then return end
    if h:HasModifier("modifier_rift_attack_probe") then
      h:RemoveModifierByName("modifier_rift_attack_probe"); Log.info("DEV", "attack probe OFF")
    else
      h:AddNewModifier(h, nil, "modifier_rift_attack_probe", {}); Log.info("DEV", "attack probe ON")
    end
  end)

  cmd("rift_spawn_dummy", "rift_spawn_dummy [unit_name] [distance]: spawn an enemy test unit in front of hero 0 (dev)", function(unit, dist)
    local h = PlayerResource:GetSelectedHeroEntity(0)
    if not h then return end
    unit = unit or "npc_dota_hero_axe"
    local pos = h:GetAbsOrigin() + h:GetForwardVector() * (tonumber(dist or "300") or 300)
    local team = DOTA_TEAM_NEUTRALS
    local u = CreateUnitByName(unit, pos, true, nil, nil, team)
    if u then
      Log.info("DEV", "spawned " .. unit .. " #" .. u:entindex() .. " (neutral team, not a match participant)")
    end
  end)

  cmd("rift_relic_now", "Spawn an extra Heart of the Rift now (dev, ACTIVE only)", function()
    if not gm.director.state:is("ACTIVE") then Log.warn("DEV", "only in ACTIVE"); return end
    Log.info("DEV", "relic_now -> " .. tostring(gm.relic:DevSpawn(gm:Now())))
  end)

  cmd("rift_relic_end", "End the current Heart of the Rift event (dev)", function()
    gm.relic:DevEnd(gm:Now())
  end)

  cmd("rift_verbose", "Toggle verbose debug logging", function()
    Log.verbose = not Log.verbose
    Log.info("DEV", "verbose=" .. tostring(Log.verbose))
  end)
end

return Debug
