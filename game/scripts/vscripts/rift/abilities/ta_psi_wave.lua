-- TA magical E: active directed Psi wave (replaces passive Psi Blades).
local B = require("rift.data.hero_balance").ta.waves_magical
ta_psi_wave = ta_psi_wave or ((type(class) == "function") and class({}) or {})
local function r(l) return math.max(1, math.min(4, l)) end
function ta_psi_wave:GetCooldown(l) return B.e_cooldown[r(l + 1)] end
function ta_psi_wave:GetManaCost() return B.e_mana end
function ta_psi_wave:OnSpellStart()
  local c = self:GetCaster()
  require("rift.engine.ta_waves").fire(c, self, c:GetAbsOrigin(), self:GetCursorPosition() - c:GetAbsOrigin(),
    B.e_base[r(self:GetLevel())])
  EmitSoundOn("Hero_TemplarAssassin.PsiBlade", c)
end
function ta_psi_wave:OnProjectileHit_ExtraData(t, _, extra) return require("rift.engine.ta_waves").hit(self, t, extra) end
