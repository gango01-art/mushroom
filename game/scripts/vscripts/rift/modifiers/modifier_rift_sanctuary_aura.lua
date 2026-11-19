local B=require("rift.core.config").sanctuary
modifier_rift_sanctuary_aura = modifier_rift_sanctuary_aura or ((type(class) == "function") and class({}) or {})
local M=modifier_rift_sanctuary_aura
function M:IsHidden()return true end
function M:IsPurgable()return false end
function M:IsAura()return true end
function M:GetAuraRadius()return B.radius end
function M:GetAuraDuration()return 0 end
function M:GetAuraSearchTeam()return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function M:GetAuraSearchType()return DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC end
function M:GetAuraSearchFlags()return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function M:GetModifierAura()return "modifier_rift_sanctuary"end
function M:GetAuraEntityReject(u)
 local gm=GameRules.RiftArena
 return not gm or not gm.sanctuary or not gm.sanctuary:sheltered(u)
end
