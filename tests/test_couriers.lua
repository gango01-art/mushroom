local S=require("engine_stub")
T.case("courier is invulnerable, owner-selectable and enemy-unselectable on each client",function()
 S.install()
 MODIFIER_STATE_INVULNERABLE=10001;MODIFIER_STATE_NO_HEALTH_BAR=10002
 MODIFIER_STATE_NO_UNIT_COLLISION=10003;MODIFIER_STATE_UNSELECTABLE=10004
 MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES=10005
 local c=S.unit("courier",{pid=0,team=2,pos=Vector(0,0,0)})
 local m=S.lua_modifier("modifier_rift_courier",c,S.ability(1))
 T.ok(m:CheckState()[MODIFIER_STATE_INVULNERABLE]);T.ok(not m:CheckState()[MODIFIER_STATE_UNSELECTABLE])
 local old=IsServer;IsServer=function()return false end
 local viewer=0;Entities={GetLocalPlayer=function()return{GetPlayerID=function()return viewer end}end}
 T.ok(not m:CheckState()[MODIFIER_STATE_UNSELECTABLE]);viewer=1
 T.ok(m:CheckState()[MODIFIER_STATE_UNSELECTABLE]);T.ok(m:CheckState()[MODIFIER_STATE_INVULNERABLE])
 IsServer=old
end)
