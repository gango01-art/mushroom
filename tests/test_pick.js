"use strict";
const fs=require("fs"),vm=require("vm"),assert=require("node:assert/strict");
const panels=new Map(),sent=[],listeners={},events={};
function panel(parent,id="") {const p={children:[],classes:new Set(),handlers:{},style:{},parent,enabled:true,
 AddClass(c){this.classes.add(c)},SetHasClass(c,b){b?this.classes.add(c):this.classes.delete(c)},
 Children(){return this.children},GetParent(){return this.parent},RemoveAndDeleteChildren(){this.children=[]},
 SetImage(s){this.image=s},SetScaling(s){this.scaling=s},SetPanelEvent(e,fn){this.handlers[e]=fn}};
 if(parent)parent.children.push(p);if(id)panels.set(id,p);return p;}
const root=panel(null),screen=panel(root,"PickScreen");
const xml=fs.readFileSync("content/panorama/layout/custom_game/rift_pick.xml","utf8");
assert.ok(!/<Panel\b[^>]*\bid=/.test(xml.match(/<Panel\b[^>]*>/)[0]));
for(const m of xml.matchAll(/\bid="([^"]+)"/g))if(m[1]!=="PickScreen")panel(screen,m[1]);
const roster={heroes:{}};
for(let i=1;i<=11;i++)roster.heroes[i]={hero:"hero"+i,abilities:{1:"q",2:"w",3:"e",4:"r"},
 physical:{name:"physical",desc:"phys",abilities:{1:"q",2:"w",3:"e",4:"custom_phys"}},
 magical:{name:"magical",desc:"magic",abilities:{1:"q",2:"w",3:"e2",4:"custom_magic"}}};
const $=s=>{assert.ok(panels.has(s.slice(1)),s);return panels.get(s.slice(1))};
$.CreatePanel=(_,p,id)=>panel(p,id);$.Localize=s=>s;$.DispatchEvent=()=>{};
const ctx=vm.createContext({$,Players:{GetLocalPlayer:()=>0,GetPlayerName:pid=>"Player "+pid},GameEvents:{Subscribe:(e,f)=>events[e]=f,SendCustomGameEventToServer:(e,d)=>sent.push({e,d})},
 CustomNetTables:{SubscribeNetTableListener:(n,f)=>listeners[n]=f,GetTableValue:(_,key)=>key==="roster"?roster:key==="picks"?{max_players:8,players:{1:{pid:0,hero:"",status:"choosing"},2:{pid:1,hero:"hero2",status:"selected"}}}:{state:"HERO_SELECTION",selection_remaining:35}}});
vm.runInContext(fs.readFileSync("content/panorama/scripts/custom_game/rift_ui_model.js","utf8"),ctx);
vm.runInContext(fs.readFileSync("content/panorama/scripts/custom_game/rift_pick.js","utf8"),ctx);
assert.equal(panels.get("PickHeroes").children[0].children[1].children.length,11);
panels.get("PickHeroes").children[0].children[1].children[4].handlers.onactivate();assert.ok(panels.get("PickPortrait").image.endsWith("hero5.png"));
assert.equal(panels.get("PickPlayers").children.length,8);assert.equal(panels.get("PickPlayers").children[1].children[0].heroname,"hero2");
ctx.RiftPickPath("magical");assert.equal(panels.get("PickAbilities").children[3].abilityname,"custom_magic");assert.equal(sent.length,0);
ctx.RiftPickConfirm();ctx.RiftPickConfirm();assert.equal(sent.length,1);assert.equal(sent[0].d.hero,"hero5");
assert.equal(panels.get("PickConfirm").enabled,false);
events.rift_pick_result({status:"error"});assert.equal(panels.get("PickConfirm").enabled,true);
ctx.RiftPickConfirm();events.rift_pick_result({status:"selected"});ctx.RiftPickConfirm();assert.equal(sent.length,2);
listeners.rift_match("rift_match","state",{state:"PREPARATION",selection_remaining:0});assert.ok(root.classes.has("Closed"));
console.log("Hero picker contract OK: eleven heroes, preview-only paths, server confirmation, retry and close.");
