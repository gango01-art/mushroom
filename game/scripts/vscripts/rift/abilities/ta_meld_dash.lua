-- TA magical W: short dash toward the cursor; a wave along the dash direction when
-- the dash completes. No invisibility, no bonus attack, no armor reduction, no
-- invulnerability or disjoint. Interrupted (root/stun/blocked path) -> no wave.
local B = require("rift.data.hero_balance").ta.waves_magical
ta_meld_dash = ta_meld_dash or ((type(class) == "function") and class({}) or {})
local function r(l) return math.max(1, math.min(4, l)) end
function ta_meld_dash:GetCooldown(l) return B.w_cooldown[r(l + 1)] end
function ta_meld_dash:GetManaCost() return B.w_mana end
function ta_meld_dash:GetCastRange() return B.w_dash[r(self:GetLevel())] end
function ta_meld_dash:CastFilterResult()
  if IsServer() and self:GetCaster():IsRooted() then return UF_FAIL_CUSTOM end
  return UF_SUCCESS
end
function ta_meld_dash:GetCustomCastError() return "#rift_err_rooted" end
function ta_meld_dash:OnSpellStart()
  local c = self:GetCaster()
  local dir = self:GetCursorPosition() - c:GetAbsOrigin()
  dir.z = 0
  if dir:Length2D() < 1 then dir = c:GetForwardVector() end
  dir = dir:Normalized()
  require("rift.engine.mods").add(c, c, self, "modifier_rift_ta_dash",
    { dx = dir.x, dy = dir.y, distance = B.w_dash[r(self:GetLevel())], duration = 0.4 })
  EmitSoundOn("Hero_TemplarAssassin.Meld", c)
end
function ta_meld_dash:OnProjectileHit_ExtraData(t, _, extra) return require("rift.engine.ta_waves").hit(self, t, extra) end
