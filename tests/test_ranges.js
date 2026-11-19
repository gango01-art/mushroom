"use strict";
const fs=require("fs"),vm=require("vm"),assert=require("node:assert/strict");
const handlers={},controls=new Map(),destroyed=[],queue=[];
let active=1,hero=10,alive=true,next=0,name="circle",radius=330;
const geometry={circle:{shape:"circle",target:"point",radius:300},self:{shape:"circle",target:"none",radius:340},line:{shape:"line",target:"point",radius:100,length:1200},cross:{shape:"cross",target:"point",radius:45,length:1100}};
const context={
 $:{RegisterForUnhandledEvent:(e,f)=>handlers[e]=f,Schedule:(_,f)=>queue.push(f)},
 Players:{GetLocalPlayerPortraitUnit:()=>hero},
 Abilities:{GetLocalPlayerActiveAbility:()=>active,GetAbilityName:()=>name,GetCastRange:()=>650,GetAOERadius:()=>radius},
 Entities:{IsAlive:()=>alive,GetAbsOrigin:()=>[0,0,0],GetForward:()=>[1,0,0],GetAbilityCount:()=>1,GetAbility:()=>1},
 GameUI:{GetScreenWorldPosition:()=>[1000,0,0],GetCursorPosition:()=>[100,100]},
 CustomNetTables:{GetTableValue:()=>geometry},ParticleAttachment_t:{PATTACH_WORLDORIGIN:0,PATTACH_ABSORIGIN_FOLLOW:1},
 Particles:{CreateParticle:()=>{const id=++next;controls.set(id,{});return id},SetParticleControl:(id,cp,v)=>controls.get(id)[cp]=v,
 SetParticleControlEnt:(id,cp,entity)=>controls.get(id).owner=entity,DestroyParticleEffect:id=>destroyed.push(id),ReleaseParticleIndex:()=>{}}
};
vm.runInNewContext(fs.readFileSync("content/panorama/scripts/custom_game/rift_ranges.js","utf8"),context);
assert.equal(next,0,"point circles use native targeting without a duplicate overlay");
name="line";radius=125;queue.shift()();assert.equal(next,1);
assert.equal(controls.get(1)[1][0],1200);assert.equal(controls.get(1)[2][1],125);assert.equal(controls.get(1).owner,hero);
active=-1;handlers.DOTAShowAbilityTooltip(null,"line");queue.shift()();assert.equal(next,2,"hover also displays geometry");
alive=false;queue.shift()();assert.equal(destroyed.length,next,"death cleans up every client particle");
alive=true;active=1;name="self";radius=340;queue.shift()();assert.equal(controls.get(3)[1][0],340);
assert.equal(controls.get(3).owner,hero,"self area is attached to the caster rather than chasing world coordinates");
name="cross";radius=45;queue.shift()();assert.equal(next,8);
assert.equal(controls.get(4)[0][0],650,"statue placement is clamped to cast distance");
assert.equal(controls.get(4)[1][0],1750);assert.equal(controls.get(4)[2][1],45);
assert.equal(controls.get(8)[1][0],1100,"cross preview restores the beam extent ring");
console.log("Native range preview logic OK: no duplicate circles, attached self area, line width, hover and cleanup.");
