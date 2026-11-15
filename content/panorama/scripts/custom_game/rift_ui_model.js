/* Pure helpers shared with Node tests; no Dota API or private player data. */
"use strict";
var RiftUIModel = (function () {
  function array(rows) {
    var out = [];
    if (Array.isArray(rows)) return rows.slice();
    for (var i = 1; rows && rows[String(i)] !== undefined; i++) out.push(rows[String(i)]);
    return out;
  }
  function time(sec) {
    sec = Math.max(0, Math.floor(Number(sec) || 0));
    return Math.floor(sec / 60) + ":" + (sec % 60 < 10 ? "0" : "") + sec % 60;
  }
  function progress(remaining, total) {
    return Math.max(0, Math.min(100, total > 0 ? 100 * remaining / total : 0));
  }
  function bySeat(rows) {
    return array(rows).sort(function (a, b) { return a.pid - b.pid; });
  }
  return { array: array, time: time, progress: progress, bySeat: bySeat };
})();
if (typeof module !== "undefined") module.exports = RiftUIModel;
