# Окружение

## Агент (облачный контейнер Claude Code) — проверено 2026-11-12
- Linux, репозиторий `/home/user/mushroom`, git, ветка `claude/pensive-curie-zvybbg`.
- Установлено: Lua 5.1 (`lua5.1`, `luac5.1`, через apt), Node 22.
- **Нет** Steam, Dota 2, Workshop Tools, компилятора ресурсов, экрана. Запуск игры здесь невозможен.
- Lua 5.1 выбран как ближайший к VScript Dota (LuaJIT, совместим с 5.1).

## Машина владельца — обследована 2026-11-12 (OP-001)
- Dota 2: `C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta`; Workshop Tools установлены.
- Addon создан владельцем под именем **`duality`**; файлы скопированы из репозитория (не junction).
  Обновление копии: `tools/sync_addon.ps1` (ничего не удаляет; копирует только новые/более новые файлы).
- Запуск: `dota_launch_custom_game duality dota`. Версия клиента не записана.
- Внутренние ID кода (`rift_*`, карта `rift_arena`) от имени папки addon не зависят.

Ожидаемая структура SDK (стандартная для Source 2, подтвердить по факту):
- `<dota>\game\dota_addons\rift_arena\` — runtime: `scripts/vscripts`, `scripts/npc`, `resource`, `addoninfo.txt`.
- `<dota>\content\dota_addons\rift_arena\` — исходники: `panorama/`, `maps/*.vmap`.
- Связь с репо: junction-ссылки `tools/link_addon.ps1` (repo/game и repo/content). Скрипт ничего
  не удаляет и не трогает существующие папки.
