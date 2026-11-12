# Направления ультимейта

Данные: `game/scripts/vscripts/rift/data/ultimate_directions.lua`. Логика выбора: `rift/core/offer_service.lua`.
Пометки: **OWNER** — значение владельца, не менять молча; **HYPOTHESIS** — стартовое предложение; **native** —
читается из KV установленного клиента (нельзя выдумывать; проверить командой `rift_dump_hero`).

## Общие правила (реализовано в чистой логике, тесты test_offers)
- Триггер: событие изучения способности с `source = "player"` и именем = `ultimate_ability_id` героя.
  Уровень героя, skill points, spawn, покупки, время — не триггеры. Путь `dev_set_level` никогда не выдаёт выбор.
- Ровно 2 карточки: physical, затем magical. Один раз за матч; ранги 2–3 меню не открывают.
- До выбора: `ultimate_locked(pid) = true` — движок должен запретить использование новой версии ульты.
- Таймаут 45 с игрового времени → `default_on_timeout` (у PA — физическое). Показывается заранее на карточке.
- Политика переноса: `keep_rank_keep_cooldown` — ранг и оставшийся cooldown способности сохраняются
  (выбор не сбрасывает cooldown). Реализация — в движке, этап C ч. 2.

## Phantom Assassin — статус: planned (герой в выборе без направлений, только для теста цикла)
Ультимейт: `phantom_assassin_coup_de_grace` — **проверить** в клиенте (OP-004).

| | Физическое «Призрачная казнь» | Магическое «Грозовые кинжалы» |
|---|---|---|
| Сохраняется | native-криты Coup de Grace | базовые эффекты Stifling Dagger |
| Заменяется | — | native-крит Coup de Grace (вкл. для кинжала) |
| Новое | активное применение: летящий дух в цель → 1 физическая крит-атака от имени PA | +1 цель кинжала (≤2), 20% цепь между двумя целями каста |
| Числа р1/р2/р3 | дальность 800, скорость 900 (HYP); cd 24/20/16 (HYP); мана 80/100/120 (HYP); множитель — native `crit_bonus` | шанс 20% (OWNER, р2–3 HYP 20%); урон 300 (OWNER) / 380 / 460 (HYP) каждой цели; радиус доп. цели 600 (HYP) |
| Proc | один удар, без предметных proc (указать в tooltip), без повторного броска native-крита | один бросок на каст при двух целях; цепь только если оба кинжала одного каста попали; без рекурсии |
| Контрплей | снаряд можно disjoint; цель умерла/недопустима → нет попадания | disjoint любого кинжала → нет цепи; цепь не скачет дальше двух целей |
| Тесты | — (движок) | test_storm.lua: 10 тестов (пары, disjoint, истечение, смешивание кастов, 20% на 20000 кастах, бюджет) |

Lina, Pudge, Axe — дизайн в BRIEF §13.3–13.5; таблицы чисел будут составлены после сверки их native-механик.

## Реальные значения из клиента (OP-004/OP-006, 2026-11-12, лог `docs/operator_logs/2026-11-12_OP-004_OP-006.log`)
**Phantom Assassin** — ульта подтверждена: `phantom_assassin_coup_de_grace` (слот 5, ULTIMATE, PASSIVE, 3 уровня).
- `crit_bonus` 200/325/450 (%), `crit_chance` 17, **`dagger_crit_chance` 34** — native-крит есть и у Stifling Dagger,
  магическое направление обязано отключать и его (как и требует BRIEF §13.2).
- Facet `special_bonus_facet_phantom_assassin_methodical`: крит каждые 6 атак (4 по крипам) вместо шанса,
  `crit_bonus` +100. Политика facets для направлений не определена — см. KNOWN_ISSUES 14.
- Stifling Dagger: `base_damage` 65/70/75/80, `attack_factor` −70/−55/−40/−25 (% урона атаки), `dagger_speed` 1200,
  cd 6, длительность замедления 2.1–3.0, `move_slow` −50; талант `extra_daggers` +2 (конфликт с «+1 цель» магической
  ветки — нужна политика).
- Другие способности PA в клиенте: phantom_strike, blur, fan_of_knives (Scepter), immaterial (innate).

**Legion Commander:** ульта `legion_commander_duel` (3 ур.): duration 4/4.5/5, cd 60/55/50, cast range 200,
`reward_damage` 10/20/30. Третий навык (заменяется статуей) — `legion_commander_moment_of_courage` (4 ур.).
**Shadow Fiend:** ульта `nevermore_requiem` (3 ур.): cd 120/110/100 (Scepter −30), radius 1000, max_soul_release 20.
Shadowraze: `shadowraze_damage` 85/150/215/280, radius 250, `stack_bonus_damage` 35/50/65/80.
**Templar Assassin:** ульта `templar_assassin_psionic_trap` (3 ур.; отдельная `templar_assassin_trap` — подспособность
взрыва, НЕ триггер выбора). Psi Blades: **`attack_spill_pct` 70/80/90/100** (коэффициент кристалла по ТЗ),
`attack_spill_range` 400–700, `attack_spill_width` 90, `meld_strike_spills` 1. Meld: `bonus_damage` 50/100/150/200,
`bonus_armor` −2/−4/−6/−8. Refraction: instances 3–6, bonus_damage 15–60.
