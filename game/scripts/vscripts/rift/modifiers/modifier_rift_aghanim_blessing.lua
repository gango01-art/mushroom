modifier_rift_aghanim_blessing = modifier_rift_aghanim_blessing or ((type(class) == "function") and class({}) or {})
function modifier_rift_aghanim_blessing:IsHidden()return true end
function modifier_rift_aghanim_blessing:IsPurgable()return false end
function modifier_rift_aghanim_blessing:RemoveOnDeath()return false end
function modifier_rift_aghanim_blessing:GetAttributes()return MODIFIER_ATTRIBUTE_PERMANENT end
