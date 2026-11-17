modifier_rift_item_break = modifier_rift_item_break or ((type(class) == "function") and class({}) or {})
require("rift.engine.solo_item_effects").break_effect(modifier_rift_item_break)
