-- LC physical ultimate "Duel": summons a champion against the chosen real enemy hero;
-- Legion Commander watches from the throne. Session: engine/lc_duel_session.
-- Rules: core/heroes/lc_duel. Numbers: hero_balance.
local B = require("rift.data.hero_balance").lc.duel_physical
lc_duel_physical = lc_duel_physical or ((type(class) == "function") and class({}) or {})
local function r(l) return math.max(1, math.min(3, l)) end
function lc_duel_physical:GetCooldown(l) return B.cooldown[r(l + 1)] end
function lc_duel_physical:GetManaCost(l) return B.mana[r(l + 1)] end
function lc_duel_physical:GetCastRange() return B.cast_range end

function lc_duel_physical:CastFilterResultTarget(target)
  if target:IsIllusion() or not target:IsHero() then return UF_FAIL_CUSTOM end
  return UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, self:GetCaster():GetTeamNumber())
end
function lc_duel_physical:GetCustomCastErrorTarget() return "#dota_hud_error_cant_cast_on_illusion" end

function lc_duel_physical:OnSpellStart()
  local c, target = self:GetCaster(), self:GetCursorTarget()
  if not target or target:IsNull() then return end
  if target.TriggerSpellAbsorb and target:TriggerSpellAbsorb(self) then return end
  require("rift.engine.lc_duel_session").start(c, self, target, r(self:GetLevel()))
  EmitSoundOn("Hero_LegionCommander.Duel.Cast", c)
end
