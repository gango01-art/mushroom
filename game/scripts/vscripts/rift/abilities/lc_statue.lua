-- LC magical third ability: a stationary archer statue (replaces Moment of Courage).
-- Lives 10 s, shoots a magic arrow at a visible enemy hero on a fixed schedule; each arrow
-- hit on a real enemy hero cuts this ability's cooldown by 2 s. State: engine/lc_magic.
-- Rules: core/heroes/lc_magic. Numbers: hero_balance.
local B = require("rift.data.hero_balance").lc.statue
lc_statue = lc_statue or ((type(class) == "function") and class({}) or {})
function lc_statue:GetCooldown() return B.cooldown end
function lc_statue:GetManaCost() return B.mana end
function lc_statue:GetCastRange() return B.cast_range end
function lc_statue:OnSpellStart()
  local c = self:GetCaster()
  require("rift.engine.lc_magic").summon(c, self, self:GetCursorPosition(), math.max(1, math.min(4, self:GetLevel())))
  EmitSoundOn("Hero_LegionCommander.PressTheAttack", c)
end
function lc_statue:OnProjectileHit_ExtraData(target, _, data)
  require("rift.engine.lc_magic").on_arrow_hit(self, target, data)
  return true
end
