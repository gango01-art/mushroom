modifier_rift_item_drums = modifier_rift_item_drums or ((type(class) == "function") and class({}) or {})
require("rift.engine.solo_item_effects").active(modifier_rift_item_drums)
