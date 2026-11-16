/* Panorama logic integration under a minimal panel/net-table adapter, not a renderer. */
"use strict";
const fs = require("fs"), vm = require("vm"), assert = require("node:assert/strict");
const base = "content/panorama/";
const panels = new Map(), tables = {}, net = {}, events = {}, sent = [], hidden = [];
function panel(type, parent, id = "") {
  const p = { type, id, parent, children: [], classes: new Set(), style: {}, handlers: {}, text: "", enabled: true,
    AddClass(c) { this.classes.add(c); }, RemoveClass(c) { this.classes.delete(c); },
    SetHasClass(c, b) { b ? this.AddClass(c) : this.RemoveClass(c); },
    ToggleClass(c) { this.SetHasClass(c, !this.classes.has(c)); },
    Children() { return this.children; }, GetParent() { return this.parent; },
    RemoveAndDeleteChildren() { this.children = []; },
    DeleteAsync() { if (this.parent) this.parent.children = this.parent.children.filter(p => p !== this); },
    SetImage(s) { this.image = s; }, SetPanelEvent(e, fn) { this.handlers[e] = fn; }
  };
  if (parent) parent.children.push(p);
  if (id) panels.set(id, p);
  return p;
}
const xml = fs.readFileSync(base + "layout/custom_game/rift_hud.xml", "utf8");
// Native Panorama rejects an id on the root panel. Keep RiftRoot inside an
// anonymous host so its selectors remain valid after ResourceCompiler builds.
assert.ok(!/<Panel\b[^>]*\bid=/.test(xml.match(/<Panel\b[^>]*>/)[0]), "Panorama root panel must be anonymous");
for (const m of xml.matchAll(/<(Panel|Label|Button)\b[^>]*\bid="([^"]+)"[^>]*>/g)) {
  const p = panel(m[1], null, m[2]);
  const classes = m[0].match(/\bclass="([^"]+)"/);
  if (classes) classes[1].split(" ").forEach(c => p.AddClass(c));
}
const $ = selector => {
  const p = panels.get(selector.slice(1));
  assert.ok(p, "Unknown XML panel " + selector);
  return p;
};
$.CreatePanel = panel;
$.Localize = token => token; // Keeping tokens makes expected localization bindings explicit.
$.Schedule = () => {};
const localPid = 2, selected = [];
const context = vm.createContext({ $, Players: { GetLocalPlayer: () => localPid, GetPlayerName: pid => "Player " + pid },
  Game: { GetGameTime: () => 100 }, GameUI: { SetDefaultUIEnabled: (k, v) => hidden.push([k, v]), SelectUnit: (e) => selected.push(e) },
  DotaDefaultUIElement_t: { DOTA_DEFAULT_UI_TOP_HEROES: 1, DOTA_DEFAULT_UI_TOP_TIMEOFDAY: 2 },
  CustomNetTables: { SubscribeNetTableListener: (t, fn) => { (net[t] ||= []).push(fn); }, GetTableValue: (t,k) => tables[t]?.[k] },
  GameEvents: { Subscribe: (e, fn) => events[e] = fn, SendCustomGameEventToServer: (e, v) => sent.push([e,v]) }
});
vm.runInContext(fs.readFileSync(base + "scripts/custom_game/rift_ui_model.js", "utf8"), context);
vm.runInContext(fs.readFileSync(base + "scripts/custom_game/rift_hud.js", "utf8"), context);
vm.runInContext(fs.readFileSync(base + "scripts/custom_game/rift_lab.js", "utf8"), context);
function publish(table, key, value) { (tables[table] ||= {})[key] = value; for (const fn of net[table]) fn(table,key,value); }
assert.ok(sent.some(([e]) => e === "rift_private_request"));
assert.equal(hidden.length, 2);
assert.ok($("#Onboarding").classes.has("Hidden"));
publish("rift_match", "state", {state:"PREPARATION", remaining:0, active_total:1080});
assert.ok($("#Onboarding").classes.has("Hidden"), "The dedicated picker owns the initial flow");
publish("rift_match", "state", {state:"ACTIVE", remaining:540, active_total:1080});
assert.equal($("#TimerLabel").text, "9:00");
assert.equal($("#ClockProgress").style.width, "50%");
assert.ok($("#Onboarding").classes.has("Hidden"));
const rows = {};
for (let i=0; i<8; i++) rows[i+1] = {pid:7-i, hero:"npc_dota_hero_axe", score:8-i, kills:4, deaths:1, assists:2, direction:"physical", alive:1, respawn:0};
publish("rift_scores", "board", {rows});
assert.equal($("#TopPlayersLeft").children.length, 4);
assert.equal($("#TopPlayersRight").children.length, 4);
const self = context.RiftSeats[localPid];
assert.ok(self.panel.classes.has("Self"));
const original = self.panel;
rows[6].alive=0; rows[6].respawn=9; rows[6].direction="magical";
publish("rift_scores", "board", {rows});
assert.equal(context.RiftSeats[localPid].panel, original, "Reuse portraits on 2Hz score updates");
assert.equal(self.death.text,"9"); assert.ok(self.panel.classes.has("Magical"));
const hero = {hero:"npc_dota_hero_axe",physical:{name:"iron",desc:"iron_desc"},magical:{name:"blood",desc:"blood_desc"}};
publish("rift_match", "roster", {heroes:{1:hero}});
assert.equal($("#HeroGallery").children.length,1);
assert.equal($("#GalleryPhysicalName").text,"#iron");
context.RiftOpenMenu(); assert.ok(!$("#Onboarding").classes.has("Hidden"));
const opt = {id:"rift_axe_physical",kind:"direction",direction:"physical",loc_name:"iron",loc_desc:"iron_desc",icon:"axe_culling_blade",is_default:1};
events.rift_private_state({visible_offer:10,pending:{1:{id:10,type:"ultimate_direction",remaining:45,options:{1:opt}}},build:{}});
assert.ok($("#Onboarding").classes.has("Hidden"), "Real offers take precedence over field guide");
assert.ok($("#RiftRoot").classes.has("Choosing"));
context.RiftCollapseOffer(); assert.ok($("#OfferOpenButton").classes.has("Visible"));
context.RiftOpenOffer();
$("#OfferCards").children[0].handlers.onactivate();
assert.equal(sent.filter(([e])=>e==="rift_offer_choose").length,1);
$("#OfferCards").children[0].handlers.onactivate();
assert.equal(sent.filter(([e])=>e==="rift_offer_choose").length,1,"Double click is pending until server reply");
events.rift_offer_result({ok:0,reason:"invalid_choice"});
assert.equal(context.RiftOffer.pendingOfferId,-1);
events.rift_private_state({visible_offer:-1,pending:{},build:{}});
assert.ok(!$("#OfferPanel").classes.has("Visible"));
assert.ok(!$("#RiftRoot").classes.has("Choosing"));
publish("rift_match","state",{state:"OVERTIME",remaining:120,active_total:1080});
assert.ok($("#RiftRoot").classes.has("Overtime"));
const model = require("../" + base + "scripts/custom_game/rift_ui_model.js");
assert.equal(model.time(-20),"0:00");assert.equal(model.time(1080),"18:00");
assert.equal(model.progress(200,100),100);assert.equal(model.progress(50,0),0);
const lab = {available:1,enabled:1,hero:hero.hero,path:"physical",rank:3,owner:localPid,free:0,gallery_count:11,target_count:1,active_entity:42};
publish("rift_match","lab",lab);
assert.ok(!$("#LabToggle").classes.has("Hidden"));
assert.ok(!$("#LabBody").classes.has("Hidden"));
assert.ok($("#LabPhysical").classes.has("Selected"));
assert.equal(selected.at(-1),42);
context.RiftLabChoosePath("magical");context.RiftLabChoosePath("magical");
assert.equal(sent.filter(([e])=>e==="rift_lab_request").length,1,"Lab must suppress repeated clicks");
events.rift_lab_result({ok:0,reason:"path_failed"});
const error=$("#LabStatus").text;publish("rift_match","lab",lab);
assert.equal($("#LabStatus").text,error,"2Hz state must not immediately erase an action error");
publish("rift_match","lab",{...lab,loading:1});
assert.equal($("#LabStatus").text,"#rift_lab_loading");
context.RiftLabChoosePath("magical");
assert.equal(sent.filter(([e])=>e==="rift_lab_request").length,1,"Cosmetic loading must block replacement clicks");
publish("rift_match","lab",lab);
publish("rift_match","state",{state:"ACTIVE",remaining:5,active_total:1080,lab:1});
assert.equal($("#TimerLabel").text,"∞");
publish("rift_match","lab",{...lab,available:0});context.RiftLabChoosePath("magical");
assert.equal(sent.filter(([e])=>e==="rift_lab_request").length,1,"Unavailable lab sends no mutation requests");
console.log("Panorama logic OK: stable 8-seat HUD, death/path updates, roster, menu, private offers, double-click guard, reconnect request. Native rendering NOT tested.");
console.log("Lab UI logic OK: roster, path/rank, focus, request throttling, persistent errors, infinite timer and availability gate.");
