"use strict";
var RiftLab = { state: null, roster: [], cards: {}, pending: 0, sequence: 0, opened: false, error: "", errorUntil: 0 };
function RiftLabOpen() {
  $("#LabPanel").RemoveClass("Hidden");
  $("#RiftRoot").AddClass("LabOpen");
  RiftHideOnboarding();
}
function RiftLabClose() {
  $("#LabPanel").AddClass("Hidden");
  $("#RiftRoot").RemoveClass("LabOpen");
}
function RiftLabSend(payload) {
  if (RiftLab.pending || !RiftLab.state || RiftLab.state.available !== 1 || RiftLab.state.loading === 1) return;
  RiftLab.pending = ++RiftLab.sequence;
  RiftLab.error = "";
  var sequence = RiftLab.pending;
  $("#LabStatus").text = $.Localize("#rift_lab_pending");
  GameEvents.SendCustomGameEventToServer("rift_lab_request", payload);
  // A dropped/rate-limited reply must not lock the controls permanently.
  $.Schedule(1.5, function () { if (RiftLab.pending === sequence) RiftLab.pending = 0; });
}
function RiftLabChoosePath(path) {
  var s = RiftLab.state;
  if (s && s.enabled === 1 && s.hero) RiftLabSend({action:"select", hero:s.hero, path:path});
}
function RiftLabFocus() {
  var s = RiftLab.state;
  if (s && s.active_entity >= 0) GameUI.SelectUnit(s.active_entity, false);
}
function RiftLabRoster(data) {
  if (!data) return;
  RiftLab.roster = RiftUIModel.array(data.heroes);
  var root = $("#LabHeroes"); root.RemoveAndDeleteChildren(); RiftLab.cards = {};
  RiftLab.roster.forEach(function (hero) {
    var card = $.CreatePanel("Button", root, ""); card.AddClass("LabHero");
    var image = $.CreatePanel("Image", card, ""); image.AddClass("LabHeroPortrait");
    image.SetImage("file://{images}/heroes/" + hero.hero + ".png");
    var name = $.CreatePanel("Label", card, ""); name.AddClass("LabHeroName"); name.text = heroName(hero.hero);
    card.SetPanelEvent("onactivate", function () {
      RiftLabSend({ action:"select", hero:hero.hero, path:RiftLab.state ? RiftLab.state.path : "base" });
    });
    RiftLab.cards[hero.hero] = card;
  });
}
function RiftLabState(s) {
  if (!s) return;
  var previous = RiftLab.state; RiftLab.state = s;
  $("#LabToggle").SetHasClass("Hidden", s.available !== 1);
  $("#LabIntro").SetHasClass("Hidden", s.enabled === 1);
  $("#LabBody").SetHasClass("Hidden", s.enabled !== 1);
  if (s.enabled === 1) {
    if (!RiftLab.opened) { RiftLab.opened = true; RiftLabOpen(); }
    $("#LabStatus").text = s.loading === 1 ? $.Localize("#rift_lab_loading") : RiftLab.error && Game.GetGameTime() < RiftLab.errorUntil ? RiftLab.error :
      heroName(s.hero) + " · R " + s.rank + " · " + locFill("rift_lab_counts", {heroes:s.gallery_count,targets:s.target_count});
    Object.keys(RiftLab.cards).forEach(function (hero) { RiftLab.cards[hero].SetHasClass("Selected", hero === s.hero); });
    ["base","physical","magical"].forEach(function (path, i) {
      $("#Lab" + ["Base","Physical","Magical"][i]).SetHasClass("Selected", s.path === path);
    });
    [1,2,3].forEach(function (rank) { $("#LabRank" + rank).SetHasClass("Selected", s.rank === rank); });
    $("#LabFree").SetHasClass("Selected", s.free === 1);
    if (!previous || previous.active_entity !== s.active_entity) RiftLabFocus();
  }
}
(function () {
  CustomNetTables.SubscribeNetTableListener("rift_match", function (_t, key, data) {
    if (key === "lab") RiftLabState(data);
    if (key === "roster") RiftLabRoster(data);
  });
  GameEvents.Subscribe("rift_lab_focus", function (data) { if (data.entity >= 0) GameUI.SelectUnit(data.entity, false); });
  GameEvents.Subscribe("rift_lab_result", function (data) {
    RiftLab.pending = 0;
    if (data.ok !== 1) {
      var key = "#rift_lab_error_" + data.reason;
      var message = $.Localize(key);
      RiftLab.error = message === key || message === key.substring(1) ? $.Localize("#rift_lab_error_generic") : message;
      RiftLab.errorUntil = Game.GetGameTime() + 4;
      $("#LabStatus").text = RiftLab.error;
    }
  });
  RiftLabRoster(CustomNetTables.GetTableValue("rift_match","roster"));
  RiftLabState(CustomNetTables.GetTableValue("rift_match","lab"));
})();
