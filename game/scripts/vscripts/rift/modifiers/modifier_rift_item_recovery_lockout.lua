modifier_rift_item_recovery_lockout = modifier_rift_item_recovery_lockout or ((type(class) == "function") and class({}) or {})
require("rift.engine.solo_item_effects").lockout(modifier_rift_item_recovery_lockout)
