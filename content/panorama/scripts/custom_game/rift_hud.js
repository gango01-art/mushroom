"use strict";
// RIFT ARENA HUD. Shows only server-confirmed state from CustomNetTables.

var localPid = Players.GetLocalPlayer();

function fmtTime(sec) {
  sec = Math.max(0, Math.floor(sec || 0));
  var m = Math.floor(sec / 60);
  var s = sec % 60;
  return m + ":" + (s < 10 ? "0" : "") + s;
}

function playerName(pid) {
  var name = Players.GetPlayerName(pid);
  return name && name.length > 0 ? name : ("Player " + pid);
}

function heroName(unitName) {
  return unitName ? $.Localize("#" + unitName) : "";
}

function rowsToArray(rows) {
  var out = [];
  if (!rows) return out;
  for (var i = 1; rows[String(i)] !== undefined; i++) out.push(rows[String(i)]);
  return out;
}

function onMatchState(data) {
  if (!data) return;
  $("#StateLabel").text = $.Localize("#rift_state_" + data.state);
  var showTimer = data.state === "ACTIVE" || data.state === "OVERTIME";
  $("#TimerLabel").text = showTimer ? fmtTime(data.remaining) : "--:--";
  $("#DevLabel").SetHasClass("Visible", data.dev === 1);
  $("#FallbackLabel").SetHasClass("Visible", data.map_fallback === 1);
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
  fillRows($("#BoardRows"), rows);
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
}

(function () {
  CustomNetTables.SubscribeNetTableListener("rift_match", function (_t, key, data) {
    if (key === "state") onMatchState(data);
    else if (key === "result") onResult(data);
  });
  CustomNetTables.SubscribeNetTableListener("rift_scores", function (_t, key, data) {
    if (key === "board") onScores(data);
  });
  // Late-created panel / reconnect: restore from current state, not from past events.
  onMatchState(CustomNetTables.GetTableValue("rift_match", "state"));
  onScores(CustomNetTables.GetTableValue("rift_scores", "board"));
  onResult(CustomNetTables.GetTableValue("rift_match", "result"));
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
    panel.RemoveClass("Visible");
    openBtn.RemoveClass("Visible");
    return;
  }
  var collapsed = RiftOffer.collapsedOfferId === offer.id;
  panel.SetHasClass("Visible", !collapsed);
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
