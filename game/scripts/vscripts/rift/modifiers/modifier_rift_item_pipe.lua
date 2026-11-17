modifier_rift_item_pipe = modifier_rift_item_pipe or ((type(class) == "function") and class({}) or {})
require("rift.engine.solo_item_effects").active(modifier_rift_item_pipe)
