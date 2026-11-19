rift_lc_courage = rift_lc_courage or ((type(class)=="function") and class({}) or {})
function rift_lc_courage:GetIntrinsicModifierName() return "modifier_rift_lc_courage" end
function rift_lc_courage:GetCooldown() return require("rift.data.hero_balance").lc.courage_physical.cooldown end
