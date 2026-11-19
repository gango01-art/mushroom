modifier_rift_item_solar = modifier_rift_item_solar or ((type(class) == "function") and class({}) or {})
require("rift.engine.solo_item_effects").active(modifier_rift_item_solar)
