# Окружение

## Агент (облачный контейнер Claude Code) — проверено 2026-11-12
- Linux, репозиторий `/home/user/mushroom`, git, ветка `claude/pensive-curie-zvybbg`.
- Установлено: Lua 5.1 (`lua5.1`, `luac5.1`, через apt), Node 22.
- **Нет** Steam, Dota 2, Workshop Tools, компилятора ресурсов, экрана. Запуск игры здесь невозможен.
- Lua 5.1 выбран как ближайший к VScript Dota (LuaJIT, совместим с 5.1).

## Машина владельца — НЕ обследована
Неизвестно: путь Steam/Dota, установлены ли Workshop Tools, версия клиента.
Нужен отчёт по задаче OP-001 (`docs/SCREEN_OPERATOR_TASKS.md`).

Ожидаемая структура SDK (стандартная для Source 2, подтвердить по факту):
- `<dota>\game\dota_addons\rift_arena\` — runtime: `scripts/vscripts`, `scripts/npc`, `resource`, `addoninfo.txt`.
- `<dota>\content\dota_addons\rift_arena\` — исходники: `panorama/`, `maps/*.vmap`.
- Связь с репо: junction-ссылки `tools/link_addon.ps1` (repo/game и repo/content). Скрипт ничего
  не удаляет и не трогает существующие папки.
