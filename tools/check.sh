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
if grep -nE '\b(GameRules|PlayerResource|Entities|CustomNetTables|ListenToGameEvent|EntIndexToHScript|Convars|Vector)\b' game/scripts/vscripts/rift/core/*.lua game/scripts/vscripts/rift/core/heroes/*.lua game/scripts/vscripts/rift/data/*.lua; then
  echo "  engine global used in rift/core"; fail=1
fi
echo "== JS syntax (node --check)"
for f in $(find content/panorama/scripts -name '*.js'); do
  node --check "$f" || { echo "  syntax error: $f"; fail=1; }
done
echo "== KV / localization"
node tools/check_kv.js || fail=1
echo "== Custom particle source links"
python3 tools/check_particles.py || fail=1
echo "== Modifier registration"
node tools/check_mods.js || fail=1
echo "== Panorama UI logic"
node tests/test_ui.js || fail=1
node tests/test_pick.js || fail=1
node tests/test_ranges.js || fail=1
node tests/test_setup.js || fail=1
node tests/test_aghanim_ui.js || fail=1
echo "== Hammer arena source (does not compile/nav-test)"
python3 tools/check_arena.py || fail=1
python3 tools/check_dmx.py || fail=1
echo "== Pure logic tests"
lua5.1 tests/run.lua || fail=1
echo "== Native tooltip balance sync"
lua5.1 tools/sync_path_tooltips.lua --check || fail=1
lua5.1 tools/sync_ability_details.lua --check || fail=1
lua5.1 tools/sync_progression.lua --check || fail=1
lua5.1 tools/sync_solo_items.lua --check || fail=1
if [ $fail -eq 0 ]; then echo "ALL CHECKS PASSED"; else echo "CHECKS FAILED"; fi
exit $fail
