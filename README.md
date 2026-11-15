# mushroom → DUALITY (addon `duality`)

В репозитории два независимых проекта:

- `index.html` — «Грибная Ферма», старая веб-страница. Не трогается.
- **RIFT ARENA** — кастомная игра для Dota 2 (`game/`, `content/`, `tools/`, `tests/`, `docs/`).

## DUALITY (рабочее название в коде — RIFT ARENA, addon ID `rift_arena`)
Короткие FFA-матчи до 8 игроков на компактной арене: 18 минут боя, очки за убийства и помощь,
выбор физического или магического направления ультимейта при первой прокачке ульты,
регулярные улучшения и переносимый артефакт «Сердце разлома».

Текущий срез: **0.3.0-lab — полигон всех 11 героев / 22 путей и установочный addon-пакет**. [Начать здесь](docs/START_HERE.md): запуск, выбор управляемого героя, пути, мишени и восстановление способностей. Реальный прогон в Dota и сборка арены в Workshop Tools пока не выполнялись.
Подробно: [docs/HANDOFF.md](docs/HANDOFF.md). ТЗ: [docs/BRIEF.md](docs/BRIEF.md).

### Быстрый старт (Windows)
1. Установить Dota 2 и DLC «Dota 2 Workshop Tools».
2. Распаковать addon-пакет и запустить **`START_DEMO.cmd`**. Он устанавливает файлы с резервными копиями и включает автополигон на штатной карте `dota`.
3. Если Tools открылось стартовым окном: выбрать addon `duality`, в Console — `dota_launch_custom_game duality dota`.
4. Выбрать героя; после начала игры использовать **«ПОЛИГОН ГЕРОЕВ»**. Можно также ввести `rift_lab`, затем `rift_lab_hero lina magical`.

**`START_MATCH.cmd`** собирает собственную арену установленным ResourceCompiler и запрашивает обычный матч. **`BUILD_MAP.cmd`** — только сборка. [Полная инструкция](docs/START_HERE.md), [карта](docs/ARENA_BUILD.md).

### Проверки без Dota
`bash tools/check.sh` — синтаксис Lua/JS, KV, локализация, тесты чистой логики (Lua 5.1, Node).

## Дизайн и арена

- [Схема арены](docs/design/arena-plan.svg).
- [Макет меню](docs/design/menu-preview.png) и [HUD](docs/design/hud-preview.png) — браузерные макеты с заглушками портретов, не скриншоты Dota.
- [Самостоятельный HTML-макет](docs/design/hud-preview.html), без внешних ресурсов.
- Карта поставляется исходником `content/maps/rift_arena.vmap`; сборка/nav в облаке не выполнялись.
