local gm=GameRules.RiftArena;assert(gm.dev and PlayerResource:GetPlayerCount()==1)
local s=gm.roshan;local u=s.unit
print("[RIFT][ROSHAN_DUMP] paid="..tostring(s.paid).." respawn_at="..tostring(s.respawn_at).." now="..gm:Now().." unit="..tostring(u))
if u and not u:IsNull()then
 print("[RIFT][ROSHAN_DUMP] alive="..tostring(u:IsAlive()).." hp="..u:GetHealth().." invulnerable="..tostring(u:IsInvulnerable()).." owner_match="..tostring(u._rift_roshan==s))
 for i=0,u:GetModifierCount()-1 do print("[RIFT][ROSHAN_DUMP] modifier="..u:GetModifierNameByIndex(i))end
end
