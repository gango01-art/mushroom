"use strict";
// RIFT ARENA HUD. Shows only server-confirmed state from CustomNetTables.

var localPid = Players.GetLocalPlayer();
var RiftSeats = {};
var RiftRoster = [];
var RiftMenuSeen = false;
var RiftMenuAuto = false;
var RiftBoardKey = "";
var RiftEvents={};
function RiftFocusEvent(kind){
 var v=RiftEvents[kind];if(!v||typeof v.x!=="number"||typeof v.y!=="number")return;
 GameUI.SetCameraTargetPosition([v.x,v.y,v.z||128],.2);
}

function fmtTime(sec) {
  return RiftUIModel.time(sec);
}

function playerName(pid) {
  var name = Players.GetPlayerName(pid);
  return name && name.length > 0 ? name : ("Player " + pid);
}

function heroName(unitName) {
  return unitName ? $.Localize("#" + unitName) : "";
}

function rowsToArray(rows) {
  return RiftUIModel.array(rows);
}

function onMatchState(data) {
  if (!data) return;
  $("#StateLabel").text = $.Localize("#rift_state_" + data.state);
  var showTimer = data.state === "ACTIVE" || data.state === "OVERTIME";
  $("#TimerLabel").text = showTimer ? fmtTime(data.remaining) : "--:--";
  if (data.lab === 1) {
    $("#TimerLabel").text = "∞";
    $("#StateLabel").text = $.Localize("#rift_lab_title");
  }
  $("#RiftRoot").SetHasClass("LabMode", data.lab === 1);
  $("#DevLabel").SetHasClass("Visible", data.dev === 1);
  $("#FallbackLabel").SetHasClass("Visible", data.map_fallback === 1);
  $("#FallbackLabel").text = $.Localize(data.lab === 1 ? "#rift_lab_native_map" : "#rift_hud_map_fallback");
  $("#RiftRoot").SetHasClass("Overtime", data.state === "OVERTIME");
  $("#ClockProgress").style.width = RiftUIModel.progress(data.remaining, data.active_total) + "%";
  if (!RiftMenuSeen && (data.state === "HERO_SELECTION" || data.state === "PREPARATION")) {
    RiftMenuSeen = true;
    RiftMenuAuto = false; // Dedicated HeroSelection screen owns the initial flow.
  }
  if (RiftMenuAuto && (data.state === "ACTIVE" || data.state === "FINISHED")) RiftHideOnboarding();
}

function onRoshan(data) {
 RiftEvents.roshan=data;
 var label=$("#RoshanStatus");if (!label) return;
 $("#RoshanEvent").SetHasClass("Hidden", !data || data.disabled === 1);
 if (!data || data.disabled === 1) return;
 var name=$.Localize("#rift_roshan_name")+": ";
 if (!data.alive) label.text=name+$.Localize("#rift_roshan_respawn")+" "+fmtTime(data.respawn);
 else if (data.moving) label.text=name+$.Localize("#rift_roshan_travelling")+" "+$.Localize("#rift_roshan_pocket_"+data.target);
 else label.text=name+$.Localize("#rift_roshan_pocket_"+data.pocket)+" · "+$.Localize("#rift_roshan_move")+" "+fmtTime(data.next_move);
}

function renderSeats(rows) {
  var seated = RiftUIModel.bySeat(rows);
  var ranks = {};
  rows.forEach(function (r, i) { ranks[r.pid] = i + 1; });
  var active = {};
  seated.forEach(function (r, i) {
    active[r.pid] = true;
    var seat = RiftSeats[r.pid];
    var parent = $(i < 4 ? "#TopPlayersLeft" : "#TopPlayersRight");
    if (!seat || seat.panel.GetParent() !== parent) {
      if (seat) seat.panel.DeleteAsync(0);
      var p = $.CreatePanel("Panel", parent, ""); p.AddClass("PlayerSeat");
      var portrait = $.CreatePanel("Image", p, ""); portrait.AddClass("SeatPortrait");
      var name = $.CreatePanel("Label", p, ""); name.AddClass("SeatName");
      var rank = $.CreatePanel("Label", p, ""); rank.AddClass("SeatRank");
      var path = $.CreatePanel("Label", p, ""); path.AddClass("SeatPath");
      var score = $.CreatePanel("Label", p, ""); score.AddClass("SeatScore");
      var death = $.CreatePanel("Label", p, ""); death.AddClass("SeatDeath");
      seat = RiftSeats[r.pid] = { panel: p, portrait: portrait, name: name, rank: rank, path: path, score: score, death: death, hero: "" };
    }
    if (r.hero && seat.hero !== r.hero) {
      seat.portrait.SetImage("file://{images}/heroes/" + r.hero + ".png"); seat.hero = r.hero;
    }
    seat.name.text = playerName(r.pid);
    seat.rank.text = "#" + ranks[r.pid];
    seat.score.text = String(r.score);
    seat.path.text = r.direction === "physical" ? "P" : r.direction === "magical" ? "M" : "";
    seat.death.text = r.alive === 0 && r.respawn > 0 ? String(r.respawn) : "";
    seat.panel.SetHasClass("Self", r.pid === localPid);
    seat.panel.SetHasClass("Dead", r.alive === 0);
    seat.panel.SetHasClass("Physical", r.direction === "physical");
    seat.panel.SetHasClass("Magical", r.direction === "magical");
  });
  Object.keys(RiftSeats).forEach(function (pid) {
    if (!active[pid]) { RiftSeats[pid].panel.DeleteAsync(0); delete RiftSeats[pid]; }
  });
}

function fillRows(container, rows) {
  container.RemoveAndDeleteChildren();
  for (var i = 0; i < rows.length; i++) {
    var r = rows[i];
    var row = $.CreatePanel("Panel", container, "");
    row.AddClass("BoardRow");
    row.SetHasClass("Self", r.pid === localPid);
    var name = $.CreatePanel("Label", row, "");
    name.AddClass("Name");
    name.text = (i + 1) + ". " + playerName(r.pid) + (r.hero ? " (" + heroName(r.hero) + ")" : "");
    var score = $.CreatePanel("Label", row, "");
    score.AddClass("Score");
    score.text = String(r.score);
    var kda = $.CreatePanel("Label", row, "");
    kda.AddClass("KDA");
    kda.text = r.kills + "/" + r.deaths + "/" + r.assists;
  }
}

function onScores(data) {
  if (!data) return;
  var rows = rowsToArray(data.rows);
  var key = JSON.stringify(rows.map(function (r) { return [r.pid, r.score, r.kills, r.deaths, r.assists, r.hero, playerName(r.pid)]; }));
  if (key !== RiftBoardKey) { fillRows($("#BoardRows"), rows); RiftBoardKey = key; }
  renderSeats(rows);
  var myScore = 0, myPlace = 0;
  for (var i = 0; i < rows.length; i++) {
    if (rows[i].pid === localPid) { myScore = rows[i].score; myPlace = i + 1; }
  }
  $("#ScoreLabel").text = $.Localize("#rift_hud_score") + ": " + myScore;
  $("#PlaceLabel").text = myPlace > 0 ? ($.Localize("#rift_hud_place") + ": " + myPlace + "/" + rows.length) : "";
}

function onResult(data) {
  if (!data) return;
  var panel = $("#Result");
  panel.AddClass("Visible");
  $("#ResultWinner").text = data.winner >= 0
    ? ($.Localize("#rift_result_winner") + ": " + playerName(data.winner))
    : "";
  $("#ResultReason").text = $.Localize("#rift_reason_" + data.reason);
  var board = CustomNetTables.GetTableValue("rift_scores", "board");
  fillRows($("#ResultRows"), rowsToArray(board ? board.rows : null));
}

function RiftHideOnboarding() {
  $("#Onboarding").AddClass("Hidden");
  RiftMenuSeen = true;
  RiftMenuAuto = false;
}

function RiftOpenMenu() {
  $("#Onboarding").RemoveClass("Hidden");
  RiftMenuSeen = true;
  RiftMenuAuto = false;
}

function RiftToggleBoard() { $("#Board").ToggleClass("Hidden"); }

function previewHero(hero, card) {
  $("#GalleryHero").text = heroName(hero.hero);
  ["physical", "magical"].forEach(function (path) {
    var prefix = path === "physical" ? "#GalleryPhysical" : "#GalleryMagical";
    $(prefix + "Name").text = hero[path] ? $.Localize("#" + hero[path].name) : "";
    $(prefix + "Desc").text = hero[path] ? $.Localize("#" + hero[path].desc) : "";
  });
  $("#HeroGallery").Children().forEach(function (p) { p.SetHasClass("Selected", p === card); });
}

function onRoster(data) {
  if (!data) return;
  RiftRoster = rowsToArray(data.heroes);
  var gallery = $("#HeroGallery");
  gallery.RemoveAndDeleteChildren();
  RiftRoster.forEach(function (hero, i) {
    var card = $.CreatePanel("Button", gallery, ""); card.AddClass("GalleryCard");
    var img = $.CreatePanel("Image", card, ""); img.AddClass("GalleryPortrait");
    img.SetImage("file://{images}/heroes/" + hero.hero + ".png");
    card.SetPanelEvent("onmouseover", function () { previewHero(hero, card); });
    card.SetPanelEvent("onactivate", function () { previewHero(hero, card); });
    if (i === 0) previewHero(hero, card);
  });
}

(function () {
  CustomNetTables.SubscribeNetTableListener("rift_match", function (_t, key, data) {
    if (key === "state") onMatchState(data);
    else if (key === "roshan") onRoshan(data);
    else if (key === "result") onResult(data);
    else if (key === "roster") onRoster(data);
  });
  CustomNetTables.SubscribeNetTableListener("rift_scores", function (_t, key, data) {
    if (key === "board") onScores(data);
  });
  // Late-created panel / reconnect: restore from current state, not from past events.
  onMatchState(CustomNetTables.GetTableValue("rift_match", "state"));
  onScores(CustomNetTables.GetTableValue("rift_scores", "board"));
  onResult(CustomNetTables.GetTableValue("rift_match", "result"));
  onRoster(CustomNetTables.GetTableValue("rift_match", "roster"));
  GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false);
  GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false);
})();

// ---------------------------------------------------------------------------
// Upgrade offers (private, addressed to this player only)
// ---------------------------------------------------------------------------
var RiftOffer = {
  state: null,          // last server-confirmed private state
  receivedAt: 0,        // Game.GetGameTime() when state arrived
  collapsedOfferId: -1, // player collapsed this offer
  pendingOfferId: -1,   // clicked, waiting for server confirmation
  statusText: ""
};

function objToArray(o) {
  var out = [];
  if (!o) return out;
  for (var i = 1; o[String(i)] !== undefined; i++) out.push(o[String(i)]);
  return out;
}

function fmtNumber(v) {
  if (typeof v !== "number") return String(v);
  if (Math.abs(v - Math.round(v)) < 1e-6) return String(Math.round(v));
  return (Math.round(v * 100) / 100).toString();
}

// Localized text with {key} placeholders filled from server-provided values.
function locFill(token, values) {
  var text = $.Localize("#" + token);
  if (values) {
    for (var k in values) text = text.split("{" + k + "}").join(fmtNumber(values[k]));
  }
  return text;
}

function visibleOffer() {
  var st = RiftOffer.state;
  if (!st || st.visible_offer < 0) return null;
  var list = objToArray(st.pending);
  for (var i = 0; i < list.length; i++) if (list[i].id === st.visible_offer) return list[i];
  return null;
}

function buildCard(parent, offer, opt) {
  var card = $.CreatePanel("Button", parent, "");
  card.AddClass("OfferCard");
  if (opt.rarity) card.AddClass(opt.rarity);
  if (opt.direction) card.AddClass(opt.direction);
  var icon = $.CreatePanel("Image", card, "");
  icon.AddClass("CardIcon");
  if (opt.icon) {
    var isItem = opt.icon.indexOf("item_") === 0;
    icon.SetHasClass("ItemIcon",isItem);
    icon.SetImage(isItem ? "file://{images}/items/" + opt.icon.substring(5) + ".png"
                         : "file://{images}/spellicons/" + opt.icon + ".png");
  }
  var body = $.CreatePanel("Panel", card, "");
  body.AddClass("CardBody");
  var name = $.CreatePanel("Label", body, "");
  name.AddClass("CardName");
  name.text = $.Localize("#" + opt.loc_name);
  var desc = $.CreatePanel("Label", body, "");
  desc.AddClass("CardDesc");
  desc.text = locFill(opt.loc_desc, opt.values);
  if (opt.total_values && opt.rank_now > 0) {
    var total = $.CreatePanel("Label", body, ""); total.AddClass("OfferTotal");
    total.text = $.Localize("#rift_offer_rank_total") + " " + locFill(opt.loc_desc, opt.total_values);
  }
  var meta = $.CreatePanel("Panel", body, "");
  meta.AddClass("CardMeta");
  var tag = $.CreatePanel("Label", meta, "");
  tag.AddClass("CardRarity");
  if (opt.kind === "direction") tag.text = $.Localize("#rift_dir_" + opt.direction);
  else if (opt.rarity) tag.text = $.Localize("#rift_rarity_" + opt.rarity);
  if (opt.kind === "upgrade") {
    var rank = $.CreatePanel("Label", meta, "");
    rank.AddClass("CardRank");
    rank.text = locFill("rift_rank", { now: opt.rank_now, next: opt.rank_next, max: opt.max_rank });
  }
  if (opt.is_default === 1) {
    var def = $.CreatePanel("Label", body, "");
    def.AddClass("CardDefault");
    def.text = $.Localize("#rift_offer_default");
  }
  var pending = RiftOffer.pendingOfferId === offer.id;
  card.SetHasClass("Pending", pending);
  card.enabled = !pending;
  card.SetPanelEvent("onactivate", function () {
    if (RiftOffer.pendingOfferId === offer.id) return;
    RiftOffer.pendingOfferId = offer.id;
    RiftOffer.statusText = $.Localize("#rift_offer_pending");
    GameEvents.SendCustomGameEventToServer("rift_offer_choose", { offer_id: offer.id, option_id: opt.id });
    renderOffer();
  });
}

function renderOffer() {
  var panel = $("#OfferPanel");
  var openBtn = $("#OfferOpenButton");
  var offer = visibleOffer();
  var count = RiftOffer.state ? objToArray(RiftOffer.state.pending).length : 0;
  if (!offer) {
    $("#RiftRoot").RemoveClass("Choosing");
    panel.RemoveClass("Visible");
    openBtn.RemoveClass("Visible");
    return;
  }
  var collapsed = RiftOffer.collapsedOfferId === offer.id;
  panel.SetHasClass("Visible", !collapsed);
  $("#RiftRoot").SetHasClass("Choosing", !collapsed);
  if (!collapsed) RiftHideOnboarding();
  panel.SetHasClass("Ultimate", offer.type === "ultimate_direction");
  openBtn.SetHasClass("Visible", collapsed);
  $("#OfferOpenLabel").text = locFill("rift_offer_open", { count: count });
  var title = offer.type === "ultimate_direction" ? "rift_offer_title_ultimate"
            : offer.type === "compensation" ? "rift_offer_title_compensation" : "rift_offer_title";
  $("#OfferTitle").text = $.Localize("#" + title);
  var cards = $("#OfferCards");
  cards.RemoveAndDeleteChildren();
  var opts = objToArray(offer.options);
  for (var i = 0; i < opts.length; i++) buildCard(cards, offer, opts[i]);
  $("#OfferStatus").text = RiftOffer.statusText;
  updateOfferTimer();
}

function updateOfferTimer() {
  var offer = visibleOffer();
  if (!offer) return;
  var left = offer.remaining - (Game.GetGameTime() - RiftOffer.receivedAt);
  $("#OfferTimer").text = locFill("rift_offer_timeout", { seconds: Math.max(0, Math.ceil(left)) });
}

function renderBuild() {
  var st = RiftOffer.state;
  if (!st) return;
  $("#BuildDirection").text = st.direction ? $.Localize("#rift_dir_" + st.direction) : "";
  var rows = $("#BuildRows");
  rows.RemoveAndDeleteChildren();
  var list = objToArray(st.build);
  var count=0;list.forEach(function(b){count+=Number(b.rank)||0;});
  $("#BuildCount").text=String(count);
  if (list.length === 0) {
    var empty = $.CreatePanel("Label", rows, "");
    empty.AddClass("BuildRow");
    empty.text = $.Localize("#rift_build_empty");
  }
  for (var i = 0; i < list.length; i++) {
    var b=list[i],row=$.CreatePanel("Panel",rows,"");row.AddClass("BuildEntry");
    var icon=$.CreatePanel("Image",row,"");icon.AddClass("BuildIcon");
    if(b.icon){var item=b.icon.indexOf("item_")===0;icon.SetImage("file://{images}/"+(item?"items/"+b.icon.substring(5):"spellicons/"+b.icon)+".png");if(item)icon.AddClass("ItemIcon");}
    var body=$.CreatePanel("Panel",row,"");body.AddClass("BuildEntryBody");
    var l = $.CreatePanel("Label", body, "");l.AddClass("BuildRow");
    l.text = $.Localize("#" + b.loc_name) + "  " + b.rank + "/" + b.max_rank;
    if(b.loc_desc){var desc=$.CreatePanel("Label",body,"");desc.AddClass("BuildEntryDesc");desc.text=locFill(b.loc_desc,b.values);}
  }
}
function RiftToggleBuild(){
  $("#BuildPanel").ToggleClass("Hidden");
  $("#BuildToggle").SetHasClass("Selected",!$("#BuildPanel").BHasClass("Hidden"));
}
function RiftBuildTooltip(){
 $.DispatchEvent("DOTAShowTextTooltip",$("#BuildToggle"),$.Localize("#rift_build_title"));
}

// Follow the actual native HUD gap; avoid fixed offsets that drift on 4:3/ultrawide.
function RiftPositionBuildButton(){
  var panel=$.GetContextPanel(),hud=panel;while(hud.GetParent())hud=hud.GetParent();
  var map=hud.FindChildTraverse("minimap_container"),portrait=hud.FindChildTraverse("portraitHUD");
  if(map&&portrait&&hud.actuallayoutheight>0){
    var scale=1080/hud.actuallayoutheight;
    var mapPos=map.GetPositionWithinWindow(), portraitPos=portrait.GetPositionWithinWindow();
    var left=Number(mapPos.x === undefined ? mapPos[0] : mapPos.x)+map.actuallayoutwidth;
    var right=Number(portraitPos.x === undefined ? portraitPos[0] : portraitPos.x);
    if(isFinite(left)&&isFinite(right)&&map.actuallayoutheight>0){
      var x=Math.max(16,(left+right)*scale/2-27),bottom=90;
      if(right-left<62/scale){x=Math.max(16,left*scale-54);bottom=map.actuallayoutheight*scale+12;}
      if(x<=520 && bottom<=360){
        $("#BuildToggle").style.marginLeft=x+"px";$("#BuildToggle").style.marginBottom=bottom+"px";
        $("#BuildPanel").style.marginLeft=Math.max(16,x-18)+"px";$("#BuildPanel").style.marginBottom=(bottom+72)+"px";
      }
    }
  }
  $.Schedule(.5,RiftPositionBuildButton);
}

function RiftCollapseOffer() {
  var offer = visibleOffer();
  if (offer) RiftOffer.collapsedOfferId = offer.id;
  renderOffer();
}

function RiftOpenOffer() {
  RiftOffer.collapsedOfferId = -1;
  renderOffer();
}

function offerTick() {
  updateOfferTimer();
  $.Schedule(0.25, offerTick);
}

(function () {
  GameEvents.Subscribe("rift_private_state", function (data) {
    RiftOffer.state = data;
    RiftOffer.receivedAt = Game.GetGameTime();
    var offer = visibleOffer();
    // confirmed state arrived: clear pending if that offer is no longer pending
    if (!offer || offer.id !== RiftOffer.pendingOfferId) {
      RiftOffer.pendingOfferId = -1;
      RiftOffer.statusText = "";
    }
    renderOffer();
    renderBuild();
  });
  GameEvents.Subscribe("rift_offer_result", function (data) {
    if (data.ok !== 1) {
      var key = "rift_offer_error_" + data.reason;
      var text = $.Localize("#" + key);
      RiftOffer.statusText = (text === key || text === "#" + key) ? $.Localize("#rift_offer_error_generic") : text;
      RiftOffer.pendingOfferId = -1;
      renderOffer();
    }
  });
  // Late panel / reconnect: ask the server for our private snapshot.
  GameEvents.SendCustomGameEventToServer("rift_private_request", {});
  offerTick();
})();

// ---------------------------------------------------------------------------
// Heart of the Rift (public state)
// ---------------------------------------------------------------------------
function onRelic(v) {
  RiftEvents.relic=v;
  if (!v) return;
  var panel = $("#RelicPanel");
  var next = $("#NextEventLabel");
  next.text = v.next_event_in >= 0 && v.state === "idle"
    ? locFill("rift_relic_next", { time: fmtTime(v.next_event_in) }) : "";
  if (v.state === "idle") { panel.RemoveClass("Visible"); return; }
  panel.AddClass("Visible");
  if (v.state === "warned") {
    $("#RelicLine1").text = locFill("rift_relic_warning", { seconds: Math.ceil(v.next_event_in) });
    $("#RelicLine2").text = "";
    return;
  }
  if (v.state === "ground") {
    $("#RelicLine1").text = $.Localize("#rift_relic_on_ground");
  } else {
    var who = v.carrier === localPid ? $.Localize("#rift_relic_you") : playerName(v.carrier);
    $("#RelicLine1").text = locFill("rift_relic_carrier", { name: who, seconds: Math.ceil(v.next_point_in) });
  }
  $("#RelicLine2").text = locFill("rift_relic_status", { time: fmtTime(v.remaining), budget: v.budget_left });
}

(function () {
  CustomNetTables.SubscribeNetTableListener("rift_match", function (_t, key, data) {
    if (key === "relic") onRelic(data);
  });
  onRelic(CustomNetTables.GetTableValue("rift_match", "relic"));
})();

onRoshan(CustomNetTables.GetTableValue("rift_match", "roshan"));
$("#BuildGlyph").SetImage("s2r://panorama/images/spellicons/attribute_bonus_png.vtex");
if (typeof $.GetContextPanel === "function") RiftPositionBuildButton();
