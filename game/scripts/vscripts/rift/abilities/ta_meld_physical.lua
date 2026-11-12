-- TA physical Meld: become invisible while standing still; the next attack gets bonus
-- physical damage. Unlike native Meld: no armor reduction. Numbers: hero_balance.
local B = require("rift.data.hero_balance").ta.meld_physical

ta_meld_physical = ta_meld_physical or ((type(class) == "function") and class({}) or {})

local function rank(l) return math.max(1, math.min(4, l)) end

function ta_meld_physical:GetCooldown(level) return B.cooldown[rank(level + 1)] end
function ta_meld_physical:GetManaCost(level) return B.mana[rank(level + 1)] end

function ta_meld_physical:OnSpellStart()
  local caster = self:GetCaster()
  caster:Stop()
  require("rift.engine.mods").add(caster, caster, self, "modifier_rift_ta_meld", {})
  EmitSoundOn("Hero_TemplarAssassin.Meld", caster)
end
