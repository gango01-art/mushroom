# Changelog

## 0.6.1-a — 2026-11-12 (сессия 11)
- OP-013 (частично): замена способностей TA работает, но пропадала Refraction. Адаптер: лог раскладки до/после,
  восстановление скрытых/удалённых неучаствующих способностей, скрытие `templar_assassin_trap` (`hide`).
- Dev-манекены: пассивные (`modifier_rift_dummy`), Axe прекешируется в Tools, `rift_clear_dummies`.
- Подсказки SummaryDescription для кристалла и Meld.

## 0.6.0-a — 2026-11-12 (сессия 10)
- OP-012 verified: модификаторы на клиенте, статы улучшений и щит видны в игре.
- TA physical «Psionic Crystal» в движке: `ta_psionic_crystal` (кристалл в пределах дальности атаки, 3 прочности,
  радиальный импульс Psi Blades с коэффициентом `attack_spill_pct`), `ta_meld_physical` (без снижения брони,
  бонус 100/160/220/280), блок native spill при ударе по кристаллу (damage filter), юнит `npc_rift_ta_crystal`.
- Первые custom KV: npc_abilities_custom.txt, npc_units_custom.txt. Dev: `rift_force_direction`. Задание OP-013.

## 0.5.3-a — 2026-11-12 (сессия 9)
- OP-011: модификаторы работают на сервере; предупреждение «unknown modifier type» — клиент.
- `addon_init.lua` (клиент+сервер) регистрирует модификаторы; список — модуль `rift/modifier_list.lua`
  (глобалы addon_game_mode не видны модулям). `check_mods.js` проверяет обе точки регистрации.
- Задание OP-012; заметка о полном перезапуске Tools после правок Lua.

## 0.5.2-a — 2026-11-12 (сессия 8)
- Отчёт оператора: дампы способностей PA/LC/SF/TA (OP-004/006 verified), найден блокер — Lua-модификаторы не создаются.
- Исправление-кандидат: модификаторы не зависят от глобального `class`; повторная регистрация в Activate
  (от оператора); `engine/mods.lua` логирует неудачное прикрепление; `tools/check_mods.js` в проверках.
- Реальные значения способностей записаны в ULTIMATE_DIRECTIONS (крит PA 200/325/450, `dagger_crit_chance` 34,
  Psi Blades `attack_spill_pct` 70–100 и др.). Задание OP-011 — первым.

## 0.5.1-a — 2026-11-12 (сессия 7)
- Первый запуск в Dota (OP-001/002): загрузка, стадии, HUD, стартовые ур./золото, улучшения — работают.
- `tools/sync_addon.ps1`: неразрушающее копирование репозитория в addon владельца `duality`.
- Инструкции и задания оператору переведены на имя addon `duality`.

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
