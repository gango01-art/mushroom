local gm=GameRules.RiftArena;local s=gm.roshan
assert(gm.dev and PlayerResource:GetPlayerCount()==1 and s.respawn_at,"real Roshan death required")
local deadline=s.respawn_at
GameRules:GetGameModeEntity():SetContextThink("rift_roshan_respawn_watch",function()
 local now=gm:Now()
 if s.unit and s.unit:IsAlive()then
  print("[RIFT][ROSHAN_RESPAWN] actual_seconds="..(now-deadline+300).." pocket="..s.index)
  assert(now>=deadline and now-deadline<1,"early/late respawn");return nil
 end
 assert(now-deadline<2,"respawn missing");return .1
end,.1)
