# Changelog

## 0.5.0-a — 2026-11-12 (сессия 6)
- Событие «Сердце разлома»: чистая логика (`core/relic_event`, 9 тестов) и движок (`engine/relic_service`):
  подбор, обзор носителя для всех, сброс при смерти/отключении/выходе за границу, очищение в overtime/конце.
- Модификатор носителя, HUD-панель события и «до следующего события» в верхней строке, локализация ru/en,
  onboarding дополнен.
- Dev: `rift_relic_now`, `rift_relic_end`. MAP_SPEC (graybox с координатами), задания OP-008/009/010. 109 тестов.

## 0.4.1-a — 2026-11-12 (сессия 5)
- Ростер альфы подтверждён владельцем: PA, LC, SF, TA.
- `direction_adapter`: блок ульты на время выбора, замена способностей с переносом уровня/cooldown
  (`core/ability_transfer`), восстановление после respawn/reconnect.
- `core/combat_ids`: ключи жизненного цикла жертвы, уникальные id эффектов, правило запрета рекурсии proc.
- Dev: `rift_probe_attacks` (логирование attack/damage событий), `rift_spawn_dummy`. Задание OP-007. 100 тестов.

## 0.4.0-a — 2026-11-12 (сессия 4)
- Новое ТЗ: Legion Commander, Shadow Fiend, Templar Assassin (docs/BRIEF_HEROES_LC_SF_TA.md). Отображаемое название — DUALITY
  (addon ID и папки `rift_arena` не менялись).
- Единый баланс `rift/data/hero_balance.lua` с пометками DR/PD и индексами массивов.
- 6 направлений в реестре (status planned, balance_ref без дублирования чисел).
- Чистая логика: lc_duel, lc_magic (spell amp + статуя), sf_physical (сферы), sf_magical (кольца), ta_physical
  (кристалл), ta_magical (волны). 32 новых теста (всего 95).
- Dev-команда `rift_dump_ability`. Документы HERO_IMPLEMENTATION_STATUS, HERO_BALANCE, HERO_INTERACTIONS; задание OP-006.

## 0.3.0-a — 2026-11-12 (сессия 3)
- Улучшения подключены к движку: `upgrade_bridge` (seed, тик предложений, событие изучения способности,
  `rift_offer_choose` с PlayerID из движка, адресная приватная рассылка, reason codes, rate limit).
- `modifier_rift_upgrade_stats`: 9 характеристик, синхронизация клиенту через transmitter data.
- 11 улучшений характеристик переведены в implemented (3 PA + 8 общих), локализация ru/en с подстановкой чисел.
- Panorama: панель выбора (карточки, редкость, ранг, таймер, pending, свернуть/открыть, ошибки), обзор сборки,
  направление в таблице.
- Предложения направлений ульты блокируются ядром, пока обе реализации не готовы.
- Dev-команды: rift_give_upgrade, rift_offer_now, rift_learn_ult, rift_upgrades. 63 теста.

## 0.2.0-a — 2026-11-12 (сессия 2)
- Чистая логика этапа C: seeded RNG, реестр улучшений и направлений с валидатором, сервис предложений
  (расписание, редкости, очередь, приоритет ульты, таймаут/fallback, идемпотентный выбор, компенсация,
  приватный snapshot), выбор направления ульты при первом изучении, логика cast context «Грозовых кинжалов».
- Данные: 8 улучшений PA, 8 общих, 2 направления PA (все status=planned до реализации в движке).
- Dev-команда `rift_dump_hero` для выгрузки реальных значений способностей.
- 57 тестов. Документы ULTIMATE_DIRECTIONS, UPGRADES, задание OP-004.

## 0.1.0-a — 2026-11-12
- Каркас addon RIFT ARENA: addoninfo, bootstrap, herolist (только PA), net tables, локализация ru/en.
- Чистая логика: конфиг, машина состояний, очки/помощь/стрики/анти-фид, overtime и тайбрейки, respawn,
  пассивный доход, выбор точки появления. 23 теста.
- Движковый слой: FFA-команды, автораспределение, фильтры стандартных наград, старт ур. 3 и 1200 золота,
  кастомные награды, респаун с щитом, контракт карты с dev-fallback, dev-команды rift_*.
- HUD: стадия, таймер, очки/место, таблица, onboarding, финальный экран.
- Инструменты: tools/check.sh, tools/check_kv.js, tools/link_addon.ps1.
- Документация: BRIEF, HANDOFF, ENVIRONMENT, GAME_DESIGN, ARCHITECTURE, NETWORK/MAP_CONTRACT, BUILD_AND_RUN,
  SCREEN_OPERATOR_TASKS, TEST_RESULTS, KNOWN_ISSUES.
