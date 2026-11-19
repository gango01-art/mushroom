modifier_rift_path_root = modifier_rift_path_root or ((type(class) == "function") and class({}) or {})
function modifier_rift_path_root:IsHidden() return false end
function modifier_rift_path_root:IsDebuff() return true end
function modifier_rift_path_root:IsPurgable() return true end
function modifier_rift_path_root:GetTexture() return "crystal_maiden_frostbite" end
function modifier_rift_path_root:CheckState() return { [MODIFIER_STATE_ROOTED] = true } end
