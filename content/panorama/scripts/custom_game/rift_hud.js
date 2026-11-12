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
