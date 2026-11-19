modifier_rift_item_glimmer_cape = modifier_rift_item_glimmer_cape or ((type(class) == "function") and class({}) or {})
require("rift.engine.solo_item_effects").active(modifier_rift_item_glimmer_cape)
