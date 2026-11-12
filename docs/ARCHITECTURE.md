# Архитектура

```
addon_game_mode.lua          bootstrap: LinkLuaModifier, Precache, Activate
rift/core/   (чистая логика, тестируется вне Dota)
  config.lua                 все числа
  match_state.lua            машина состояний, однократное завершение
  scoring.lua                очки, помощь, стрики, анти-фид, атрибуция окружения
  match_director.lua         конец времени, overtime, тайбрейки
  rules.lua                  respawn-время, пассивный доход, выбор точки появления
rift/engine/ (адаптеры Dota API)
  game_mode.lua              настройки движка, события, герои, награды, thinker
  ui_bridge.lua              CustomNetTables (публичные данные)
  map_contract.lua           поиск сущностей карты, dev-fallback
  debug_commands.lua         rift_* команды (только dev)
  log.lua                    [RIFT][LEVEL][TAG] логи, Log.try для неуверенных API
rift/modifiers/              Lua-модификаторы
content/panorama/            HUD (rift_hud.xml/.js/.css)
```

Владение состоянием: всё авторитетное — в `GameRules.RiftArena` (сервер). UI только читает net tables.
Один thinker (0.25 с): пассивный доход, `director:tick`, публикация UI (≤ 2 раз/с; при событиях — сразу).
