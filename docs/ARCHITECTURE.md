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

## Срез 0.2: дополнительные герои и арена

`rift/data/expansion.lua` — семь профилей героев, по два пути с числовыми playtest defaults. Реестр `ultimate_directions.lua` добавляет 14 направлений к прежним восьми. `hero_balance.expansion` ссылается на те же данные; отдельной копии баланса нет.

`abilities/path_ultimate.lua` объявляет отдельный Lua-класс на каждое KV-имя, а исполнение делегирует `engine/path_combat.lua`. Примитивы: targeted verdict, фиксированная линия, зона, подвижная зона, серия прыжков, обрываемый расстоянием tether, развеиваемая stance с OnAttackLanded. Геометрия и расчёт урона — чистый `core/path_math.lua`. Сессии ограничены количеством тиков и прекращаются при смерти владельца/FINISHED. Частицы уничтожаются явно; FFA-лечение ограничено общей суммой на тик.

`tools/sync_path_tooltips.lua` генерирует native AbilitySpecial из профилей. После настройки баланса запускать его из корня, затем `bash tools/check.sh`. Проверка `--check` защищает от рассинхронизации подсказок и сервера.

`engine/arena_service.lua` ограничивает главных героев границами валидной карты. `core/arena.lua` проверяет XY-геометрию. Полностью отсутствующий или частичный контракт карты использует целиком dev fallback, не смесь настоящих спавнов и отсутствующих relic-точек.

HUD получает публичный roster, standings/respawn (2 Hz) и прежние приватные offers. Панели верхнего ряда переиспользуются; таблица пересоздаётся только при изменении отображаемых данных. UI не рассчитывает результаты боя и не выбирает путь до подтверждения сервера.


## 0.3: лаборатория

`core/laboratory.lua` задаёт допустимые запросы, roster, aliases и поиск проходимых свободных слотов. `engine/laboratory.lua` отвечает за single-player/dev authorization, assigned hero через ReplaceHeroWith, parked gallery, цели, управление сессией и cleanup. В обычном матче RPC не действует.

Normal match keeps one-time directions. Lab resets offers and replaces the actual hero to switch paths; it never attempts to reverse arbitrary modifiers/hidden abilities on an existing kit. `Adapter:ApplyToHero` reuses the actual direction transform for non-player gallery copies. Gallery actors are invulnerable/command-restricted and never become scoring participants. The player tests abilities on a separately assigned, controllable hero.

`GameMode:Think` branches to lab before economy/director/offers/relic scheduling. Damage/death bookkeeping does not award score; mortal target kills exercise LC magical progression explicitly. Unit spawns/deaths retain combat generations. Helpers owned by an old hero are removed before replacement.

`rift_lab.js` manages the panel; public net state enables controls only in the applicable runtime. All mutation checks are repeated on the server. `duality_local.kv` carries only an installer-set launch preference, honored in dev mode. No secret or arbitrary code is loaded from it.
