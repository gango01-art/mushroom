-- TA physical direction ultimate: place an attackable crystal within attack range.
-- Rules: rift/core/heroes/ta_physical.lua. Numbers: rift/data/hero_balance.lua.
local B = require("rift.data.hero_balance").ta.crystal_physical

ta_psionic_crystal = ta_psionic_crystal or ((type(class) == "function") and class({}) or {})

local function rank(l) return math.max(1, math.min(3, l)) end

function ta_psionic_crystal:GetCooldown(level)
  local cut = require("rift.engine.build_bonus").get(self:GetCaster(), "crystal_cooldown_reduction")
  return math.max(1, B.cooldown[rank(level + 1)] - cut)
end
function ta_psionic_crystal:GetManaCost(level) return B.mana end
function ta_psionic_crystal:GetAOERadius() return B.radius[rank(self:GetLevel())] end
-- Placement range = owner's current attack range (no hidden doubling of bonuses).
function ta_psionic_crystal:GetCastRange() return self:GetCaster():Script_GetAttackRange() end

function ta_psionic_crystal:OnSpellStart()
  local caster = self:GetCaster()
  local point = self:GetCursorPosition()
  -- One crystal at a time: early recast replaces the old one without a pulse.
  if self.crystal and not self.crystal:IsNull() and self.crystal:IsAlive() then
    local m = self.crystal:FindModifierByName("modifier_rift_ta_crystal")
    if m then m.replaced = true; m:Destroy() end
  end
  local unit = CreateUnitByName("npc_rift_ta_crystal", point, true, nil, nil, DOTA_TEAM_NEUTRALS)
  if not unit then
    print("[RIFT][ERROR][TA] failed to create npc_rift_ta_crystal")
    return
  end
  unit:SetOwner(caster)
  require("rift.engine.mods").add(unit, caster, self, "modifier_rift_ta_crystal", { duration = B.lifetime })
  self.crystal = unit
  EmitSoundOn("Hero_TemplarAssassin.Trap", unit)
end
