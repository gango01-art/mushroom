# CLAUDE.md — как продолжать RIFT ARENA

- Требования владельца: `docs/BRIEF.md`. Текущее состояние и следующий шаг: `docs/HANDOFF.md`.
- Общение по-русски; код/идентификаторы/файлы по-английски.
- `index.html` (Грибная Ферма) — чужой проект в этом репо, не изменять.
- Ветка разработки: `claude/pensive-curie-zvybbg`. Не публиковать в Workshop.

## Структура
- `game/scripts/vscripts/rift/core/` — чистая логика (без глобалов движка; проверяется `tools/check.sh`).
- `game/scripts/vscripts/rift/engine/` — адаптеры Dota API. Неуверенные вызовы API — через `Log.try`.
- `game/scripts/vscripts/rift/modifiers/` — Lua-модификаторы (регистрация в `addon_game_mode.lua`).
- `content/panorama/` — исходники UI. `game/resource/` — локализация (ru + en, ключи синхронны).
- Все числа — `rift/core/config.lua`. Не дублировать числа в UI.

## Правила работы
1. Перед изменениями: `bash tools/check.sh` должен быть зелёным; после — тоже.
2. Новая чистая логика → тест в `tests/` (добавить suite в `tests/run.lua`).
3. Нельзя отмечать что-либо «проверено в Dota» без отчёта оператора/владельца (`docs/TEST_RESULTS.md`).
4. Задачи для GUI — в `docs/SCREEN_OPERATOR_TASKS.md` в установленном формате.
5. В конце сессии: обновить HANDOFF, TEST_RESULTS, CHANGELOG; коммит; push в ветку.
6. Герой попадает в `game/scripts/npc/herolist.txt` только когда оба направления ульты реализованы.
