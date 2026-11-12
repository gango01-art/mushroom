# HANDOFF

Обновлено: 2026-11-12, сессия 2 (авто-старт 07:11 МСК).

## Текущий этап
A/B — код написан, в Dota **не запускался**. Ждём OP-001/OP-002 от оператора.

## Что реально работает (подтверждено)
- `bash tools/check.sh` зелёный: синтаксис, KV, локализация, 57 чистых тестов.
- Сессия 2: чистая логика этапа C готова и протестирована (rng, upgrade_registry, offer_service,
  pa_storm_daggers; данные rift/data/*). В движок ещё НЕ подключена.

## Что написано, но не проверено в игре
Весь движковый слой: стадии, команды FFA, стартовые уровень/золото, фильтры наград, пассивный доход,
убийства/помощь/респаун/щит, конец матча/overtime, HUD/таблица/финальный экран, dev-команды.

## Авто-старт
Задача по расписанию «RIFT ARENA — авто-старт разработки» (по Москве: 02:11, 07:11, 12:11, 17:11,
22:11) будит эту сессию: продолжать по этому файлу.

## Следующие конкретные шаги (по порядку)
1. Если в SCREEN_OPERATOR_TASKS.md есть отчёты OP-002/003/004 — сначала исправить ошибки; по OP-004
   зафиксировать реальные значения PA в ULTIMATE_DIRECTIONS.md и data.
2. Этап C ч. 2a — подключить offer_service к движку (не зависит от OP-004):
   - `rift/engine/upgrade_bridge.lua`: создать Offers с серверным seed (RandomInt на старте, лог seed),
     add_player при инициализации героя, tick в thinker (regular_open = state ACTIVE), слушатель
     `dota_player_learned_ability` (проверить имя события и поля в текущем API; PlayerID брать из события),
     применение applied (gold через Grant; upgrade → handler), CustomGameEventManager для
     `rift_offer_choose` (PlayerID из аргументов callback движка), адресная отправка
     `rift_offer_update` через `CustomGameEventManager:Send_ServerToPlayer`, `rift_snapshot_request`.
   - Обработчик `stat_bonus`: один Lua-модификатор `modifier_rift_upgrade_stats`, читающий суммы из сборки
     игрока (attack_damage, move_speed, armor, health, mana, attack_speed, spell_amp, health_regen,
     status_resistance). После реализации — перевести u_* и pa_keen_edge/veil_step/shadow_guard в implemented.
   - Panorama: панель выбора (карточки, редкость, ранг, таймер, pending после клика, свернуть/открыть),
     индикатор очереди; ключи локализации rift_up_* и rift_dir_*.
   - Добавить reason codes и события в NETWORK_CONTRACT.md.
3. Этап C ч. 2b (после OP-004): блок ульты до выбора (SetActivated/модификатор), PA physical (дух → крит),
   PA magical (2-й кинжал + отключение native-крита + цепь через pa_storm_daggers), перевести направления
   PA в implemented; только тогда PA считается полноценно поддержанной.
4. Задания оператору для Hammer-карты (этап D) — после проверки цикла матча.

## Блокеры
- Нет доступа к Dota у агента: всё игровое — через оператора/владельца.
