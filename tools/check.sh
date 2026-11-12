#!/usr/bin/env bash
# Static checks + pure logic tests. Does NOT prove the addon loads in Dota.
set -u
cd "$(dirname "$0")/.."
fail=0
echo "== Lua syntax (luac5.1 -p)"
while IFS= read -r f; do
  luac5.1 -p "$f" || { echo "  syntax error: $f"; fail=1; }
done < <(find game/scripts/vscripts tests -name '*.lua')
echo "== Pure core must not touch engine globals"
if grep -nE '\b(GameRules|PlayerResource|Entities|CustomNetTables|ListenToGameEvent|EntIndexToHScript|Convars|Vector)\b' game/scripts/vscripts/rift/core/*.lua; then
  echo "  engine global used in rift/core"; fail=1
fi
echo "== JS syntax (node --check)"
for f in $(find content/panorama/scripts -name '*.js'); do
  node --check "$f" || { echo "  syntax error: $f"; fail=1; }
done
echo "== KV / localization"
node tools/check_kv.js || fail=1
echo "== Pure logic tests"
lua5.1 tests/run.lua || fail=1
if [ $fail -eq 0 ]; then echo "ALL CHECKS PASSED"; else echo "CHECKS FAILED"; fi
exit $fail
