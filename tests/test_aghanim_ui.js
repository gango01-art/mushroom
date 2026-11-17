// DUALITY badge uses the inspected hero's confirmed ownership, not native flags.
"use strict";
const fs=require("fs"),vm=require("vm"),assert=require("node:assert/strict");
const panels={};let next,entity=101;
function panel(type,parent,id){const p={id,parent,style:{},events:{},classes:new Set(),
 GetParent(){return this.parent;},FindChildTraverse(n){return panels[n];},
 SetPanelEvent(n,f){this.events[n]=f;},AddClass(n){this.classes.add(n);},
 SetHasClass(n,b){b?this.classes.add(n):this.classes.delete(n);}};
 if(id)panels[id]=p;return p;}
const root=panel("Panel",null,"hud"),context=panel("Panel",root,"context");
panel("Panel",root,"AghsStatusScepterContainer");panel("Panel",root,"AghsStatusShard");
panel("Panel",root,"AghsStatusScepter");panel("Panel",root,"AghsStatusScepterScene");panel("Panel",root,"AghsStatusShardScene");
for(const n of ["AghanimInfo","AghanimPath","AghanimScepterOwned","AghanimShardOwned","AghanimScepterText","AghanimShardText"])panel("Panel",context,n);
const board={rows:{1:{direction:"physical",aghanim:{entity:101,scepter:1,shard:0,primary:"ta_psionic_crystal",shared:""}},
 2:{direction:"magical",aghanim:{entity:202,scepter:0,shard:1,primary:"lc_statue",shared:"legion_commander_overwhelming_odds"}}}};
const $=s=>panels[s.slice(1)];$.GetContextPanel=()=>context;$.Localize=t=>t;$.CreatePanel=panel;$.Schedule=(_,f)=>{next=f;};
vm.runInNewContext(fs.readFileSync("content/panorama/scripts/custom_game/rift_aghanim.js","utf8"),{$,
 Players:{GetLocalPlayerPortraitUnit:()=>entity},CustomNetTables:{GetTableValue:()=>board}});
const badge=panels.AghsStatusScepterContainer;
badge.events.onmouseover();
assert(!panels.AghanimInfo.classes.has("Hidden"));
assert.equal(panels.AghanimScepterText.text,"#DOTA_Tooltip_ability_ta_psionic_crystal_scepter_description");
assert(panels.AghsStatusScepter.style.backgroundImage.includes("scepter_on_psd"));
assert(panels.AghsStatusShard.style.backgroundImage.includes("shard_psd"));
assert(!panels.RiftAghanimIcon0,"no overlapping item image");
assert.equal(panels.AghsStatusScepterScene.style.visibility,"collapse");
entity=202;next();
assert.equal(panels.AghanimShardText.text,"#DOTA_Tooltip_ability_legion_commander_overwhelming_odds_shard_description");
assert(panels.AghsStatusScepter.style.backgroundImage.includes("scepter_psd"));
assert(panels.AghsStatusShard.style.backgroundImage.includes("shard_on_psd"));
entity=999;next();assert(panels.AghanimInfo.classes.has("Hidden"));
assert(panels.AghsStatusShard.style.backgroundImage.includes("shard_psd"),"unknown portrait must clear prior ownership");
entity=101;board.rows[1].aghanim.primary="";board.rows[1].direction="";next();
assert.equal(panels.AghanimScepterText.text,"#rift_agh_choose_path");
badge.events.onmouseout();assert(panels.AghanimInfo.classes.has("Hidden"));
console.log("Aghanim HUD logic OK: inspected hero, shared Shard, ownership, no stale text and path gate. Native rendering NOT tested.");
