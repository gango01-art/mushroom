-- TA magical Q: defensive Refraction charges on the caster + one directed wave.
local B = require("rift.data.hero_balance").ta
ta_refraction_magical = ta_refraction_magical or ((type(class) == "function") and class({}) or {})
local function r(l) return math.max(1, math.min(4, l)) end
function ta_refraction_magical:GetCooldown(l) return B.waves_magical.q_cooldown[r(l + 1)] end
function ta_refraction_magical:GetManaCost() return B.waves_magical.q_mana end
function ta_refraction_magical:OnSpellStart()
  local c = self:GetCaster()
  require("rift.engine.mods").add(c, c, self, "modifier_rift_ta_refraction", { duration = B.refraction_magical.duration })
  local dir = self:GetCursorPosition() - c:GetAbsOrigin()
  require("rift.engine.ta_waves").fire(c, self, c:GetAbsOrigin(), dir, B.waves_magical.q_base)
  EmitSoundOn("Hero_TemplarAssassin.Refraction", c)
end
function ta_refraction_magical:OnProjectileHit_ExtraData(t, _, extra) return require("rift.engine.ta_waves").hit(self, t, extra) end
