# mushroom → DUALITY (addon `duality`)

В репозитории два независимых проекта:

- `index.html` — «Грибная Ферма», старая веб-страница. Не трогается.
- **RIFT ARENA** — кастомная игра для Dota 2 (`game/`, `content/`, `tools/`, `tests/`, `docs/`).

## DUALITY (рабочее название в коде — RIFT ARENA, addon ID `rift_arena`)
Короткие FFA-матчи до 8 игроков на компактной арене: 18 минут боя, очки за убийства и помощь,
выбор физического или магического направления ультимейта при первой прокачке ульты,
регулярные улучшения и переносимый артефакт «Сердце разлома».

Текущий срез: **0.2.0-alpha — 11 героев / 22 пути, исходник арены и обновлённый HUD**. Новые механики и карта требуют прогона в Workshop Tools. Инструкция передачи: [docs/PLAYTEST_0_2.md](docs/PLAYTEST_0_2.md).
Подробно: [docs/HANDOFF.md](docs/HANDOFF.md). ТЗ: [docs/BRIEF.md](docs/BRIEF.md).

### Быстрый старт (Windows)
1. Установить DLC «Dota 2 Workshop Tools» (Steam → Dota 2 → Свойства → DLC).
2. `powershell -ExecutionPolicy Bypass -File tools\link_addon.ps1`
3. Запустить Workshop Tools, выбрать addon `duality`, в консоли:
   `dota_launch_custom_game duality rift_arena` (после сборки карты в Hammer; [инструкция](docs/ARENA_BUILD.md))

Подробности: [docs/BUILD_AND_RUN.md](docs/BUILD_AND_RUN.md).

### Проверки без Dota
`bash tools/check.sh` — синтаксис Lua/JS, KV, локализация, тесты чистой логики (Lua 5.1, Node).

## Дизайн и арена

- [Схема арены](docs/design/arena-plan.svg).
- [Макет меню](docs/design/menu-preview.png) и [HUD](docs/design/hud-preview.png) — браузерные макеты с заглушками портретов, не скриншоты Dota.
- [Самостоятельный HTML-макет](docs/design/hud-preview.html), без внешних ресурсов.
- Карта поставляется исходником `content/maps/rift_arena.vmap`; сборка/nav в облаке не выполнялись.
