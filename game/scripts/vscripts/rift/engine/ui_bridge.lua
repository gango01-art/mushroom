-- Server -> client state replication via CustomNetTables (public data only).
-- Private per-player data (upgrade offers) will use addressed custom events; see
-- docs/NETWORK_CONTRACT.md. Publishing is throttled; forced on important changes.

local Config = require("rift.core.config")

local UiBridge = {}
UiBridge.__index = UiBridge

local MIN_INTERVAL = 0.5

function UiBridge.new(gm)
  return setmetatable({ gm = gm, last = -1e9 }, UiBridge)
end

function UiBridge:PublishRoster()
  CustomNetTables:SetTableValue("rift_match","settings",{teams=self.gm.teams,max_players=Config.match.max_players,
    active_seconds=Config.match.active_seconds,selection_seconds=Config.match.hero_selection_seconds})
  CustomNetTables:SetTableValue("rift_match","geometry",require("rift.data.geometry"))
  local heroes, seen = {}, {}
  for _, d in ipairs(require("rift.data.ultimate_directions")) do
    local h = seen[d.hero_id]
    if not h then
      h = { hero = d.hero_id, abilities=require("rift.data.selection")[d.hero_id],attribute=require("rift.data.attributes")[d.hero_id] }
      seen[d.hero_id] = h
    end
    h[d.direction] = { name = d.loc_name, desc = d.loc_desc, icon = d.icon }
    local preview={}
    for i,native in ipairs(h.abilities or {}) do
      local ability=native
      for _,swap in ipairs(d.swaps or {}) do if swap.from==native then ability=swap.to end end
      preview[tostring(i)]=ability
    end
    h[d.direction].abilities=preview
  end
  local names = {}
  for name in pairs(seen) do names[#names + 1] = name end
  table.sort(names)
  for i, name in ipairs(names) do heroes[tostring(i)] = seen[name] end
  CustomNetTables:SetTableValue("rift_match", "roster", { heroes = heroes })
end

function UiBridge:Publish(force)
  local raw = GameRules:GetGameTime()
  if not force and raw - self.last < MIN_INTERVAL then return end
  self.last = raw
  local gm = self.gm
  local st = gm.director.state
  local now = gm:Now()
  local remaining
  if st:is("OVERTIME") then remaining = st:overtime_remaining(now)
  elseif st:is("ACTIVE") then remaining = st:active_remaining(now)
  else remaining = 0 end

  local contenders = {}
  if gm.director.contender_list then
    for i, pid in ipairs(gm.director.contender_list) do contenders[tostring(i)] = pid end
  end

  CustomNetTables:SetTableValue("rift_match", "state", {
    schema = Config.SCHEMA_VERSION,
    version = Config.VERSION,
    state = st.state,
    elapsed = math.floor(st:active_elapsed(now)),
    remaining = math.ceil(remaining),
    selection_remaining=gm.selection_started and math.max(0,math.ceil(Config.match.hero_selection_seconds-(raw-gm.selection_started))) or Config.match.hero_selection_seconds,
    active_total = Config.match.active_seconds,
    dev = gm.dev and 1 or 0,
    lab = gm.lab and gm.lab.enabled and 1 or 0,
    map_fallback = (gm.map and gm.map.fallback) and 1 or 0,
    contenders = contenders,
  })

  if gm.relic then
    CustomNetTables:SetTableValue("rift_match", "relic", gm.relic:View(now, st:active_elapsed(now)))
  end

  self:PublishScores() -- also keeps death/respawn indicators current (2 Hz)
  if gm.lab then gm.lab:Publish() end
end

function UiBridge:PublishScores()
  local rows = {}
  for i, r in ipairs(self.gm.scoring:standings()) do
    local hero = PlayerResource:GetSelectedHeroEntity(r.pid)
    rows[tostring(i)] = {
      pid = r.pid, score = r.score, kills = r.kills, deaths = r.deaths, assists = r.assists,
      hero = (hero and not hero:IsNull()) and hero:GetUnitName() or "",
      direction = (self.gm.upgrades and self.gm.upgrades:Direction(r.pid)) or "",
      alive = hero and not hero:IsNull() and hero:IsAlive() and 1 or 0,
      respawn = hero and not hero:IsNull() and not hero:IsAlive() and math.ceil(math.max(0, hero:GetTimeUntilRespawn())) or 0,
    }
  end
  CustomNetTables:SetTableValue("rift_scores", "board", { rows = rows })
end

function UiBridge:PublishResult()
  local st = self.gm.director.state
  local r = st.result or {}
  self:PublishScores()
  CustomNetTables:SetTableValue("rift_match", "result", {
    winner = r.winner ~= nil and r.winner or -1,
    reason = r.reason or "unknown",
  })
end

return UiBridge
