local Stub=require("engine_stub")
local function setup()
  local S=Stub.install();local f={phase=3,replies={},loads={},picks={},snapshots={}}
  _G.DOTA_GAMERULES_STATE_HERO_SELECTION=3
  _G.DOTA_MAX_TEAM_PLAYERS=8
  GameRules.State_Get=function()return f.phase end
  local p={SetSelectedHero=function(_,hero)f.picks[#f.picks+1]=hero end}
  f.players={[0]=p}
  PlayerResource.GetPlayer=function(_,pid) return f.players[pid] end
  _G.PrecacheUnitByNameAsync=function(hero,cb,pid)f.loads[#f.loads+1]={hero=hero,callback=cb,pid=pid}end
  _G.CustomGameEventManager={RegisterListener=function()end,Send_ServerToPlayer=function(_,_,event,data)f.replies[#f.replies+1]=data end}
  _G.CustomNetTables={SetTableValue=function(_,_,key,data) f.snapshots[key]=data end}
  local reg={hero_enabled=function(_,hero)return hero=="npc_dota_hero_axe" or hero=="npc_dota_hero_crystal_maiden" end}
  f.service=require("rift.engine.hero_selection").new({upgrades={registry=reg}});f.S=S
  return f
end
T.case("picker confirms the allowed hero only after player-specific precache",function()
  local f=setup();T.ok(f.service:Pick({PlayerID=0,hero="npc_dota_hero_axe"}))
  T.eq(#f.picks,0);T.eq(f.loads[1].pid,0);T.eq(f.replies[1].status,"loading")
  f.loads[1].callback();T.eq(#f.picks,1);T.eq(f.picks[1],"npc_dota_hero_axe")
  T.eq(f.replies[2].status,"selected");f.loads[1].callback();T.eq(#f.picks,1)
  T.ok(not f.service:Pick({PlayerID=0,hero="npc_dota_hero_axe"}))
end)
T.case("public picker snapshot contains other players' confirmed heroes without revealing previews",function()
 local f=setup();f.players[1]={SetSelectedHero=function()end}
 f.service:Publish();T.eq(f.snapshots.picks.players["2"].pid,1);T.eq(f.snapshots.picks.players["2"].hero,"")
 f.service:Pick({PlayerID=1,hero="npc_dota_hero_crystal_maiden"})
 T.eq(f.snapshots.picks.players["2"].status,"loading");T.eq(f.snapshots.picks.players["2"].hero,"")
 f.loads[1].callback();T.eq(f.snapshots.picks.players["2"].hero,"npc_dota_hero_crystal_maiden")
 T.eq(f.snapshots.picks.players["2"].status,"selected")
end)
T.case("picker rejects unsupported heroes, absent players and requests after selection",function()
  local f=setup()
  T.ok(not f.service:Pick({PlayerID=0,hero="npc_dota_hero_invoker"}))
  T.ok(not f.service:Pick({PlayerID=999,hero="npc_dota_hero_axe"}))
  f.phase=5;T.ok(not f.service:Pick({PlayerID=0,hero="npc_dota_hero_axe"}));T.eq(#f.loads,0)
end)
T.case("picker ignores late precache callbacks after timeout or phase change",function()
  local f=setup();f.service:Pick({PlayerID=0,hero="npc_dota_hero_axe"})
  f.S.advance(31);f.loads[1].callback();T.eq(#f.picks,0);T.eq(f.replies[#f.replies].status,"error")
  f=setup();f.service:Pick({PlayerID=0,hero="npc_dota_hero_axe"});f.phase=5;f.loads[1].callback()
  T.eq(#f.picks,0);T.eq(f.replies[#f.replies].status,"closed")
end)
T.case("every selectable hero has exactly four preview abilities and both path previews",function()
  local map=require("rift.data.selection")
  for _,d in ipairs(require("rift.data.ultimate_directions")) do
    T.eq(#map[d.hero_id],4);T.eq(map[d.hero_id][4],d.ultimate_ability_id)
  end
end)
