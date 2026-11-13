-- Ability bar layout when a direction is applied (engine/direction_adapter) on a fake hero
-- with real slot semantics. Guards the bugs seen in Dota: hidden Meld/Psi Blades (OP-018),
-- ultimate moved off R, lost levels. Uses the shipped direction data for all four heroes.
local Stub = require("engine_stub")
local F = require("fixtures")

local ULT = { phantom_assassin_coup_de_grace = true, pa_phantom_execution = true, pa_storm_charge = true,
  legion_commander_duel = true, lc_duel_physical = true, lc_duel_magical = true, nevermore_requiem = true,
  sf_requiem_physical = true, templar_assassin_psionic_trap = true, ta_psionic_crystal = true, ta_psionic_blast = true }

local function fake_hero(S, unit_name, slots, hidden)
  local h = S.hero(unit_name, 0, 2, Vector(0, 0, 0), {})
  h.slots = {}
  local function make(name, is_hidden)
    local a = S.ability(0)
    a.name, a.hidden, a.active = name, is_hidden or false, true
    function a:GetAbilityName() return self.name end
    function a:IsHidden() return self.hidden end
    function a:SetHidden(v) self.hidden = v end
    function a:SetLevel(l) self.level = l end
    function a:SetActivated(v) self.active = v end
    function a:GetMaxLevel() return ULT[self.name] and 3 or 4 end
    function a:GetCooldown() return 10 end
    function a:GetAbilityType() return ULT[self.name] and 1 or 0 end
    function a:GetAbilityIndex() for i, x in pairs(h.slots) do if x == self then return i end end end
    return a
  end
  for i, name in ipairs(slots) do h.slots[i - 1] = make(name, hidden and hidden[name]) end
  local m = getmetatable(h)
  local H = setmetatable({}, { __index = m.__index })
  function H.GetAbilityCount() return 24 end
  function H.GetAbilityByIndex(_, i) return h.slots[i] end
  function H.FindAbilityByName(_, n) for _, a in pairs(h.slots) do if a.name == n then return a end end end
  function H.AddAbility(_, n)
    for i = 0, 23 do if not h.slots[i] then h.slots[i] = make(n, true); return h.slots[i] end end
  end
  function H.RemoveAbility(_, n) for i, a in pairs(h.slots) do if a.name == n then h.slots[i] = nil end end end
  -- Engine semantics: the two abilities trade slots; enable flag true = shown, false = hidden.
  function H.SwapAbilities(self, n1, n2, e1, e2)
    local a, b = self:FindAbilityByName(n1), self:FindAbilityByName(n2)
    local ia, ib = a:GetAbilityIndex(), b:GetAbilityIndex()
    h.slots[ia], h.slots[ib] = b, a
    a.hidden, b.hidden = not e1, not e2
  end
  setmetatable(h, { __index = function(t, k) if H[k] then return H[k] end return m.__index(t, k) end })
  _G.ABILITY_TYPE_ULTIMATE = 1
  return h
end

local function bar(h)
  local out = {}
  for i = 0, 5 do
    local a = h.slots[i]
    out[i] = (a and not a.hidden) and a.name or nil
  end
  return out
end

local function adapter(S, hero_name)
  local _, dirs = F.data("shipped")
  local by_id = {}
  for _, d in ipairs(dirs) do by_id[d.id] = d end
  local Adapter = require("rift.engine.direction_adapter")
  local bridge = { registry = { direction = function(_, id) return by_id[id] end,
                                ultimate_ability = function() return nil end },
                   offers = { player = function() return { hero = hero_name } end } }
  return Adapter.new(bridge), by_id
end

local function level(h, name, l) h:FindAbilityByName(name):SetLevel(l) end

T.case("TA: normal Dota bar before the choice, ultimate on R", function()
  local S = Stub.install()
  local h = fake_hero(S, "npc_dota_hero_templar_assassin",
    { "templar_assassin_meld", "templar_assassin_psi_blades", "templar_assassin_trap", "templar_assassin_trap_teleport",
      "templar_assassin_psionic_trap", "templar_assassin_inner_peace" }, { templar_assassin_trap_teleport = true })
  local A = adapter(S, h.name)
  A:ApplyKit(h)
  local b = bar(h)
  T.eq(b[0], "templar_assassin_refraction"); T.eq(b[1], "templar_assassin_meld")
  T.eq(b[2], "templar_assassin_psi_blades"); T.eq(b[5], "templar_assassin_psionic_trap")
end)

local function ta_after_kit(S)
  local h = fake_hero(S, "npc_dota_hero_templar_assassin",
    { "templar_assassin_meld", "templar_assassin_psi_blades", "templar_assassin_trap", "templar_assassin_trap_teleport",
      "templar_assassin_psionic_trap", "templar_assassin_inner_peace" }, { templar_assassin_trap_teleport = true })
  local A, dirs = adapter(S, h.name)
  A:ApplyKit(h)
  level(h, "templar_assassin_refraction", 1); level(h, "templar_assassin_meld", 1)
  level(h, "templar_assassin_psi_blades", 3); level(h, "templar_assassin_psionic_trap", 1)
  return h, A, dirs
end

T.case("TA physical: Q and E untouched, W replaced with its level, crystal on R, trap removed", function()
  local S = Stub.install()
  local h, A, dirs = ta_after_kit(S)
  A:Apply(0, dirs.ta_crystal_physical)
  local b = bar(h)
  T.eq(b[0], "templar_assassin_refraction"); T.eq(b[1], "ta_meld_physical")
  T.eq(b[2], "templar_assassin_psi_blades"); T.eq(b[5], "ta_psionic_crystal")
  T.eq(h:FindAbilityByName("ta_meld_physical"):GetLevel(), 1)
  T.eq(h:FindAbilityByName("templar_assassin_psi_blades"):GetLevel(), 3)
  T.eq(h:FindAbilityByName("templar_assassin_trap"), nil)
end)

T.case("TA magical: all four replaced, build 1/1/3 carried over, ultimate on R", function()
  local S = Stub.install()
  local h, A, dirs = ta_after_kit(S)
  A:Apply(0, dirs.ta_waves_magical)
  local b = bar(h)
  T.eq(b[0], "ta_refraction_magical"); T.eq(b[1], "ta_meld_dash"); T.eq(b[2], "ta_psi_wave"); T.eq(b[5], "ta_psionic_blast")
  T.eq(h:FindAbilityByName("ta_refraction_magical"):GetLevel(), 1)
  T.eq(h:FindAbilityByName("ta_meld_dash"):GetLevel(), 1)
  T.eq(h:FindAbilityByName("ta_psi_wave"):GetLevel(), 3)
  T.eq(h:FindAbilityByName("ta_psionic_blast"):GetLevel(), 1)
  T.ok(h:HasModifier("modifier_rift_ta_no_attack"))
end)

local HEROES = {
  { hero = "npc_dota_hero_phantom_assassin",
    slots = { "phantom_assassin_stifling_dagger", "phantom_assassin_phantom_strike", "phantom_assassin_blur",
              "phantom_assassin_fan_of_knives", "phantom_assassin_immaterial", "phantom_assassin_coup_de_grace" },
    hidden = { phantom_assassin_fan_of_knives = true },
    cases = {
      pa_phantom_execution = { [0] = "phantom_assassin_stifling_dagger", [1] = "phantom_assassin_phantom_strike",
                               [2] = "phantom_assassin_blur", [5] = "pa_phantom_execution" },
      pa_storm_daggers = { [0] = "pa_storm_dagger", [1] = "phantom_assassin_phantom_strike",
                           [2] = "phantom_assassin_blur", [5] = "pa_storm_charge" } } },
  { hero = "npc_dota_hero_legion_commander",
    slots = { "legion_commander_overwhelming_odds", "legion_commander_press_the_attack",
              "legion_commander_moment_of_courage", "generic_hidden", "generic_hidden2", "legion_commander_duel" },
    hidden = { generic_hidden = true, generic_hidden2 = true },
    cases = {
      lc_duel_physical = { [0] = "legion_commander_overwhelming_odds", [1] = "legion_commander_press_the_attack",
                           [2] = "legion_commander_moment_of_courage", [5] = "lc_duel_physical" },
      lc_duel_magical = { [0] = "legion_commander_overwhelming_odds", [1] = "legion_commander_press_the_attack",
                          [2] = "lc_statue", [5] = "lc_duel_magical" } } },
  { hero = "npc_dota_hero_nevermore",
    slots = { "nevermore_shadowraze1", "nevermore_shadowraze2", "nevermore_shadowraze3", "nevermore_necromastery",
              "nevermore_dark_lord", "nevermore_requiem" },
    cases = {
      sf_requiem_physical = { [0] = "nevermore_shadowraze1", [1] = "nevermore_shadowraze2", [2] = "nevermore_shadowraze3",
                              [3] = "nevermore_necromastery", [4] = "nevermore_dark_lord", [5] = "sf_requiem_physical" },
      sf_requiem_magical = { [0] = "nevermore_shadowraze1", [1] = "nevermore_shadowraze2", [2] = "nevermore_shadowraze3",
                             [3] = "nevermore_necromastery", [4] = "nevermore_dark_lord", [5] = "nevermore_requiem" } } },
}

for _, spec in ipairs(HEROES) do
  for dir_id, expect in pairs(spec.cases) do
    T.case(dir_id .. ": bar after the choice, levels carried, ultimate on R", function()
      local S = Stub.install()
      local h = fake_hero(S, spec.hero, spec.slots, spec.hidden)
      local A, dirs = adapter(S, h.name)
      A:ApplyKit(h)
      for i = 0, 2 do h.slots[i]:SetLevel(i + 1) end
      h.slots[5]:SetLevel(1)
      A:Apply(0, dirs[dir_id])
      local b = bar(h)
      for slot, name in pairs(expect) do T.eq(b[slot], name, "slot " .. slot) end
      for i = 0, 2 do T.eq(h.slots[i]:GetLevel(), i + 1, "level of slot " .. i) end
      T.eq(h.slots[5]:GetLevel(), 1, "ultimate rank kept")
      T.eq(h.slots[5]:GetAbilityType(), 1, "an ultimate sits on R")
    end)
  end
end
