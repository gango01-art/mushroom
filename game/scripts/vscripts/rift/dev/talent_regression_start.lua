local gm=GameRules.RiftArena
assert(gm and gm.dev and PlayerResource:GetPlayerCount()==1)
GameRules:GetGameModeEntity():SetContextThink("rift_talent_regression_start",function()
 if not gm.director.state:is("ACTIVE")or not PlayerResource:GetSelectedHeroEntity(0)then return .1 end
 local ok,e=pcall(require,"rift.dev.talent_native_probe")
 if not ok then print("[RIFT][TALENT_FIX] START ERROR "..tostring(e))end
 return nil
end,.1)
