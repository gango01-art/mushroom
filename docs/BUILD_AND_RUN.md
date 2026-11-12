# Сборка и запуск

Статус процедуры: **проверена владельцем 2026-11-12** (копия файлов в addon `duality`, запуск на карте `dota`).

## Установка владельца (копии файлов)
1. `git pull` в репозитории.
2. `powershell -ExecutionPolicy Bypass -File tools\sync_addon.ps1 -WhatIf`, затем без `-WhatIf`
   (ничего не удаляет; не перезаписывает более новые файлы в addon).
3. Полный перезапуск кастомки: `dota_launch_custom_game duality dota`.

Альтернатива без копирования — junction-ссылки (ниже), но существующую папку `duality` скрипт не тронет.

## Подключение
`tools/link_addon.ps1` создаёт junction-ссылки:
- `<dota>\game\dota_addons\rift_arena` → `<repo>\game`
- `<dota>\content\dota_addons\rift_arena` → `<repo>\content`

## Запуск
Workshop Tools → addon `duality` → консоль: `dota_launch_custom_game duality dota`.
Карта `dota` — временная dev-карта (стандартная карта Dota). На ней нет сущностей
контракта арены, поэтому HUD показывает предупреждение и используется DEV FALLBACK кольцо точек.
Карта `rift_arena` появится после задания оператору по Hammer (этап D).

## Перезагрузка
- Lua-скрипты: `script_reload` в консоли перезагружает VScript, но bootstrap/слушатели событий
  уже зарегистрированы — надёжно только полный перезапуск (`dota_launch_custom_game ...`).
- Panorama: изменения в `content/panorama` компилируются Tools при сохранении; панель
  перезагружается (иногда нужен перезапуск игры).
- KV (`herolist.txt`, `addoninfo.txt`, net tables, локализация) — полный перезапуск.

## Dev-команды (только Tools-режим или sv_cheats)
| Команда | Действие |
|---|---|
| `rift_status` | стадия, время, счёт, K/D/A |
| `rift_skip <сек>` | сдвинуть логические часы матча |
| `rift_addscore <pid> <n>` | начислить очки (только ACTIVE/OVERTIME) |
| `rift_kill <pid>` | убить героя без убийцы |
| `rift_map_check` | перепроверить контракт карты |
| `rift_verbose` | подробный лог |

Engine-команды (не наши): `dota_launch_custom_game`, `dota_create_fake_clients`, `script_reload`.

## Проверки без Dota
`bash tools/check.sh`
