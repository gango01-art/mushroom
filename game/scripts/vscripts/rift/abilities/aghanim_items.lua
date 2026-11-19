for _,name in ipairs({"item_ultimate_scepter","item_ultimate_scepter_2","item_aghanims_shard"})do
 local A=(type(class)=="function")and class({})or{};_G[name]=A
 function A:GetIntrinsicModifierName()return "modifier_rift_aghanim_item"end
end
