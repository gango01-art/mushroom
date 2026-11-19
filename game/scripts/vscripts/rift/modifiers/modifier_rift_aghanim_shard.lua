modifier_rift_aghanim_shard = modifier_rift_aghanim_shard or ((type(class) == "function") and class({}) or {})
function modifier_rift_aghanim_shard:IsHidden()return true end
function modifier_rift_aghanim_shard:IsPurgable()return false end
function modifier_rift_aghanim_shard:RemoveOnDeath()return false end
function modifier_rift_aghanim_shard:GetAttributes()return MODIFIER_ATTRIBUTE_PERMANENT end
