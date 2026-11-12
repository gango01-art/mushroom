// Checks: KV1 files have balanced braces/quotes; every #token used in Panorama
// and every rift_state_/rift_reason_ key produced by Lua exists in both languages.
"use strict";
const fs = require("fs");
const path = require("path");
let fail = false;
const err = (m) => { console.log("  " + m); fail = true; };

function walk(dir, ext, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, ext, out); else if (p.endsWith(ext)) out.push(p);
  }
  return out;
}

function checkKV1(file) {
  const src = fs.readFileSync(file, "utf8");
  let depth = 0, inStr = false;
  for (let i = 0; i < src.length; i++) {
    const c = src[i];
    if (inStr) { if (c === "\\") i++; else if (c === '"') inStr = false; continue; }
    if (c === "/" && src[i + 1] === "/") { while (i < src.length && src[i] !== "\n") i++; continue; }
    if (c === '"') inStr = true;
    else if (c === "{") depth++;
    else if (c === "}") { depth--; if (depth < 0) return err(`${file}: unbalanced }`); }
  }
  if (inStr) err(`${file}: unterminated string`);
  if (depth !== 0) err(`${file}: unbalanced braces (${depth})`);
}

function tokens(file) {
  const src = fs.readFileSync(file, "utf8");
  const m = {}; const re = /^\s*"([^"]+)"\s+"((?:[^"\\]|\\.)*)"/gm; let x;
  while ((x = re.exec(src))) m[x[1]] = x[2];
  return m;
}

["game/addoninfo.txt", "game/scripts/npc/herolist.txt", ...walk("game/resource", ".txt"),
 ...walk("game/scripts/npc", ".txt")].forEach(f => fs.existsSync(f) && checkKV1(f));

const langs = { russian: tokens("game/resource/addon_russian.txt"), english: tokens("game/resource/addon_english.txt") };
const used = new Set();
for (const f of [...walk("content/panorama", ".xml"), ...walk("content/panorama", ".js")]) {
  const src = fs.readFileSync(f, "utf8");
  for (const m of src.matchAll(/["'(]#(rift_[A-Za-z0-9_]+)["')]/g)) if (!m[1].endsWith("_")) used.add(m[1]);
}
const states = ["BOOT","SETUP","HERO_SELECTION","PREPARATION","ACTIVE","OVERTIME","FINISHED"];
states.forEach(s => used.add("rift_state_" + s));
// reasons emitted by Lua: collect reason = "..." literals
for (const f of walk("game/scripts/vscripts", ".lua")) {
  const src = fs.readFileSync(f, "utf8");
  for (const m of src.matchAll(/reason\s*=\s*"([a-z_]+)"/g)) {
    if (!["kill","environment_credit","no_credit"].includes(m[1])) used.add("rift_reason_" + m[1]);
  }
}
for (const k of used) for (const [lang, t] of Object.entries(langs)) if (!(k in t)) err(`missing token ${k} in ${lang}`);
for (const k of Object.keys(langs.russian)) if (!(k in langs.english)) err(`token ${k} only in russian`);
for (const k of Object.keys(langs.english)) if (!(k in langs.russian)) err(`token ${k} only in english`);
console.log(fail ? "  KV/localization: FAILED" : `  KV/localization OK (${used.size} tokens checked)`);
process.exit(fail ? 1 : 0);
