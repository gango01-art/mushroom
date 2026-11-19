-- Repeated same-hero resource lifetime regression. Single-player lab only.
local gm=GameRules.RiftArena
assert(gm and gm.dev and gm.lab and gm.lab.enabled and gm.lab:Allowed(gm.lab.owner),"single-player lab required")
local lab=gm.lab
local paths={"base","physical","magical","base","physical","magical"}
local i,phase,ready,deadline=0,"next"
GameRules:GetGameModeEntity():SetContextThink("rift_jug_reload",function()
 local now=GameRules:GetGameTime()
 if phase=="next"then
  i=i+1;if not paths[i]then print("[RIFT][RELOAD] DONE six Juggernaut replacements");return nil end
  lab:Clear();assert(lab:Select("npc_dota_hero_juggernaut",paths[i]))
  deadline=now+40;ready=nil;phase="load"
 else
  assert(now<deadline,"precache timeout")
  if lab.loading then return .1 end
  if not ready then ready=now+2;return .1 end
  if now<ready then return .1 end
  print("[RIFT][RELOAD] pass="..i.." path="..paths[i]);phase="next"
 end
 return .1
end,.1)
