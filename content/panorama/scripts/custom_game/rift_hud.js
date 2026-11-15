"use strict";
// RIFT ARENA HUD. Shows only server-confirmed state from CustomNetTables.

var localPid = Players.GetLocalPlayer();
var RiftSeats = {};
var RiftRoster = [];
var RiftMenuSeen = false;
var RiftMenuAuto = false;
var RiftBoardKey = "";

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
  $("#DevLabel").SetHasClass("Visible", data.dev === 1);
  $("#FallbackLabel").SetHasClass("Visible", data.map_fallback === 1);
  $("#RiftRoot").SetHasClass("Overtime", data.state === "OVERTIME");
  $("#ClockProgress").style.width = RiftUIModel.progress(data.remaining, data.active_total) + "%";
  if (!RiftMenuSeen && (data.state === "HERO_SELECTION" || data.state === "PREPARATION")) {
    $("#Onboarding").RemoveClass("Hidden");
    RiftMenuSeen = true;
    RiftMenuAuto = true;
  }
  if (RiftMenuAuto && (data.state === "ACTIVE" || data.state === "FINISHED")) RiftHideOnboarding();
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
  var top = $.CreatePanel("Panel", card, "");
  top.AddClass("CardTop");
  var icon = $.CreatePanel("Image", top, "");
  icon.AddClass("CardIcon");
  if (opt.icon) {
    var isItem = opt.icon.indexOf("item_") === 0;
    icon.SetImage(isItem ? "file://{images}/items/" + opt.icon.substring(5) + ".png"
                         : "file://{images}/spellicons/" + opt.icon + ".png");
  }
  var name = $.CreatePanel("Label", top, "");
  name.AddClass("CardName");
  name.text = $.Localize("#" + opt.loc_name);
  var tag = $.CreatePanel("Label", card, "");
  tag.AddClass("CardRarity");
  if (opt.kind === "direction") tag.text = $.Localize("#rift_dir_" + opt.direction);
  else if (opt.rarity) tag.text = $.Localize("#rift_rarity_" + opt.rarity);
  var desc = $.CreatePanel("Label", card, "");
  desc.AddClass("CardDesc");
  desc.text = locFill(opt.loc_desc, opt.values);
  if (opt.kind === "upgrade") {
    var rank = $.CreatePanel("Label", card, "");
    rank.AddClass("CardRank");
    rank.text = locFill("rift_rank", { now: opt.rank_now, next: opt.rank_next, max: opt.max_rank });
  }
  if (opt.is_default === 1) {
    var def = $.CreatePanel("Label", card, "");
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
  if (list.length === 0) {
    var empty = $.CreatePanel("Label", rows, "");
    empty.AddClass("BuildRow");
    empty.text = $.Localize("#rift_build_empty");
  }
  for (var i = 0; i < list.length; i++) {
    var l = $.CreatePanel("Label", rows, "");
    l.AddClass("BuildRow");
    l.text = $.Localize("#" + list[i].loc_name) + " " + list[i].rank + "/" + list[i].max_rank;
  }
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
