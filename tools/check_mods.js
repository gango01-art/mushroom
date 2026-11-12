// Every modifier file is registered in RIFT_MODIFIERS, defines its global table
// with the class/plain-table guard, and every modifier name used in code exists.
"use strict";
const fs = require("fs");
const path = require("path");
const root = "game/scripts/vscripts";
let fail = false;
const err = (m) => { console.log("  " + m); fail = true; };
const boot = fs.readFileSync(path.join(root, "addon_game_mode.lua"), "utf8");
const listBlock = (boot.match(/RIFT_MODIFIERS\s*=\s*\{([\s\S]*?)\}/) || [])[1] || "";
const registered = new Set([...listBlock.matchAll(/"([a-z0-9_]+)"/g)].map(m => m[1]));
const dir = path.join(root, "rift/modifiers");
const files = fs.readdirSync(dir).filter(f => f.endsWith(".lua")).map(f => f.slice(0, -4));
for (const n of files) {
  if (!registered.has(n)) err(`modifier file ${n}.lua not in RIFT_MODIFIERS`);
  const src = fs.readFileSync(path.join(dir, n + ".lua"), "utf8");
  if (!new RegExp(`^${n} = ${n} or \\(\\(type\\(class\\) == "function"\\) and class\\(\\{\\}\\) or \\{\\}\\)`, "m").test(src))
    err(`${n}.lua: missing guarded global definition`);
}
for (const n of registered) if (!files.includes(n)) err(`RIFT_MODIFIERS has ${n} but no file`);
function walk(d, out = []) {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, e.name);
    if (e.isDirectory()) walk(p, out); else if (p.endsWith(".lua")) out.push(p);
  }
  return out;
}
for (const f of walk(root)) {
  const src = fs.readFileSync(f, "utf8");
  for (const m of src.matchAll(/"(modifier_rift_[a-z0-9_]+)"/g)) if (!registered.has(m[1])) err(`${f}: unknown modifier ${m[1]}`);
}
console.log(fail ? "  modifiers: FAILED" : `  modifiers OK (${registered.size} registered)`);
process.exit(fail ? 1 : 0);
