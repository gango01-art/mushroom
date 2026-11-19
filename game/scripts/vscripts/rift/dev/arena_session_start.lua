-- Explicit console opt-in; let the ward probe finish, then test actual bosses.
local gm=GameRules.RiftArena
assert(gm and gm.dev and PlayerResource:GetPlayerCount()==1)
GameRules:GetGameModeEntity():SetContextThink("rift_arena_session_start",function()
 if not gm.director.state:is("ACTIVE")or gm.director.state:active_elapsed(gm:Now())<95 then return .2 end
 local ok,e=pcall(require,"rift.dev.boss_probe")
 if not ok then print("[RIFT][BOSS_PROBE] START ERROR "..tostring(e))end
 return nil
end,.2)
