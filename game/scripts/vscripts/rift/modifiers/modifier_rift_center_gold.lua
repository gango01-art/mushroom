modifier_rift_center_gold = modifier_rift_center_gold or ((type(class) == "function") and class({}) or {})
function modifier_rift_center_gold:IsPurgable()return false end
function modifier_rift_center_gold:GetTexture()return "item_hand_of_midas"end
