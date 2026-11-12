-- SF physical "Requiem of Souls": 15 s of red spheres that empower attacks, and a
-- physical bonus on Shadowraze hits. Rules: core/heroes/sf_physical. Numbers: hero_balance.
local B = require("rift.data.hero_balance").sf.requiem_physical
sf_requiem_physical = sf_requiem_physical or ((type(class) == "function") and class({}) or {})
local function r(l) return math.max(1, math.min(3, l)) end
function sf_requiem_physical:GetCooldown(l) return B.cooldown[r(l + 1)] end
function sf_requiem_physical:GetManaCost(l) return B.mana[r(l + 1)] end
function sf_requiem_physical:OnSpellStart()
  local c = self:GetCaster()
  require("rift.engine.mods").add(c, c, self, "modifier_rift_sf_spheres", { duration = B.duration })
  EmitSoundOn("Hero_Nevermore.RequiemOfSoulsCast", c)
end
