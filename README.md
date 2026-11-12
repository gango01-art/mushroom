# mushroom → DUALITY (addon `rift_arena`)

В репозитории два независимых проекта:

- `index.html` — «Грибная Ферма», старая веб-страница. Не трогается.
- **RIFT ARENA** — кастомная игра для Dota 2 (`game/`, `content/`, `tools/`, `tests/`, `docs/`).

## DUALITY (рабочее название в коде — RIFT ARENA, addon ID `rift_arena`)
Короткие FFA-матчи до 8 игроков на компактной арене: 18 минут боя, очки за убийства и помощь,
выбор физического или магического направления ультимейта при первой прокачке ульты,
регулярные улучшения и переносимый артефакт «Сердце разлома».

Текущий статус: **этап A/B (фундамент + цикл матча)**, в Dota ещё не запускался.
Подробно: [docs/HANDOFF.md](docs/HANDOFF.md). ТЗ: [docs/BRIEF.md](docs/BRIEF.md).

### Быстрый старт (Windows)
1. Установить DLC «Dota 2 Workshop Tools» (Steam → Dota 2 → Свойства → DLC).
2. `powershell -ExecutionPolicy Bypass -File tools\link_addon.ps1`
3. Запустить Workshop Tools, выбрать addon `rift_arena`, в консоли:
   `dota_launch_custom_game rift_arena dota`

Подробности: [docs/BUILD_AND_RUN.md](docs/BUILD_AND_RUN.md).

### Проверки без Dota
`bash tools/check.sh` — синтаксис Lua/JS, KV, локализация, тесты чистой логики (Lua 5.1, Node).
