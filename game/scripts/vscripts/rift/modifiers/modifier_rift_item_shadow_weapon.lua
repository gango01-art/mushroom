modifier_rift_item_shadow_weapon = modifier_rift_item_shadow_weapon or ((type(class) == "function") and class({}) or {})
require("rift.engine.solo_item_effects").active(modifier_rift_item_shadow_weapon)
