local B = require("rift.data.hero_balance").passives
rift_sven_echo = class({})
function rift_sven_echo:GetIntrinsicModifierName() return "modifier_rift_sven_echo" end
function rift_sven_echo:GetCooldown(level) return B.sven_echo_cooldown[math.max(1,math.min(4,require("rift.engine.ability_level")(self,level)))] end
