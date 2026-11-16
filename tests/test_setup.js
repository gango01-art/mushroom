"use strict";
const fs=require("fs"),vm=require("vm"),assert=require("node:assert/strict");
const panels=new Map(),calls=[],queue=[];let host=false,locked=false,state=2;
function panel(parent,id=""){const p={children:[],classes:new Set(),handlers:{},enabled:true,
 AddClass(c){this.classes.add(c)},SetHasClass(c,b){b?this.classes.add(c):this.classes.delete(c)},GetParent(){return parent},
 RemoveAndDeleteChildren(){this.children=[]},SetImage(s){this.image=s},SetPanelEvent(e,f){this.handlers[e]=f}};
 if(parent)parent.children.push(p);if(id)panels.set(id,p);return p;}
const root=panel(null),screen=panel(root,"SetupScreen");
const xml=fs.readFileSync("content/panorama/layout/custom_game/rift_setup.xml","utf8");
for(const m of xml.matchAll(/\bid="([^"]+)"/g))if(m[1]!=="SetupScreen")panel(screen,m[1]);
const $=s=>panels.get(s.slice(1));$.CreatePanel=(_,p,id)=>panel(p,id);$.Localize=s=>s;$.Schedule=(_,f)=>queue.push(f);
const ctx=vm.createContext({$,Players:{GetLocalPlayer:()=>0,GetPlayerName:pid=>"Player "+pid},
 CustomNetTables:{GetTableValue:()=>({teams:{1:2,2:3,3:6,4:7,5:8,6:9,7:10,8:11},max_players:8})},
 DOTA_GameState:{DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP:2},Game:{GetState:()=>state,GetLocalPlayerInfo:()=>({player_has_host_privileges:host}),
 GetAllPlayerIDs:()=>[0,1],GetPlayerIDsOnTeam:t=>t===2?[0]:t===3?[1]:[],GetPlayerInfo:()=>({player_steamid:"0"}),
 GetTeamSelectionLocked:()=>locked,GetStateTransitionTime:()=>100,GetGameTime:()=>97,GetUnassignedPlayerIDs:()=>[],
 AutoAssignPlayersToTeams:()=>calls.push("assign"),SetAutoLaunchEnabled:()=>{},SetTeamSelectionLocked:b=>locked=b,
 SetRemainingSetupTime:n=>calls.push(n),PlayerJoinTeam:t=>calls.push(t)}});
vm.runInContext(fs.readFileSync("content/panorama/scripts/custom_game/rift_ui_model.js","utf8"),ctx);
vm.runInContext(fs.readFileSync("content/panorama/scripts/custom_game/rift_setup.js","utf8"),ctx);
assert.equal(panels.get("SetupSeats").children.length,4);assert.ok(panels.get("SetupSeats").children.every(row=>row.children.length===2));assert.equal(panels.get("SetupStart").enabled,false);
ctx.RiftSetupStart();assert.equal(calls.length,0,"non-host cannot submit start controls");
panels.get("SetupSeats").children[1].children[0].handlers.onactivate();assert.equal(calls.pop(),6);
host=true;queue.shift()();assert.equal(panels.get("SetupStart").enabled,true);
ctx.RiftSetupStart();assert.equal(locked,true);assert.deepEqual(calls,["assign",3]);
ctx.RiftSetupStart();assert.equal(locked,false);assert.equal(calls.pop(),-1);
state=3;queue.shift()();assert.ok(root.classes.has("Closed"));
console.log("Setup UI logic OK: eight FFA seats, host-only start, native join, cancel and phase transition.");
