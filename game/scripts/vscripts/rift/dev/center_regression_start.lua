-- Explicit operator load: attach the native test to the start of this match.
local gm=GameRules.RiftArena
assert(gm and gm.dev and PlayerResource:GetPlayerCount()==1,"single-player Tools required")
GameRules:GetGameModeEntity():SetContextThink("rift_center_regression_start",function()
 if not gm.director.state:is("ACTIVE")or not PlayerResource:GetSelectedHeroEntity(0)then return .1 end
 package.loaded["rift.dev.center_wards_probe"]=nil
 local ok,err=pcall(require,"rift.dev.center_wards_probe")
 if not ok then print("[RIFT][CENTER_WARDS] START ERROR "..tostring(err))end
 return nil
end,.1)
