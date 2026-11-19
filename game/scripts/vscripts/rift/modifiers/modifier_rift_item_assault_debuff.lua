modifier_rift_item_assault_debuff = modifier_rift_item_assault_debuff or ((type(class) == "function") and class({}) or {})
require("rift.engine.solo_item_effects").aura(modifier_rift_item_assault_debuff)
