# Обычные улучшения

Данные: `rift/data/upgrades.lua`. **implemented** (обработчик `stat_bonus`, модификатор
`modifier_rift_upgrade_stats`): pa_keen_edge, pa_veil_step, pa_shadow_guard и все u_*. Остальные — planned
(нужны обработчики направлений PA) и в игре не предлагаются. Проверка в Dota — OP-005.

| id | Герой | Редкость | Направление | Ранги | Эффект |
|---|---|---|---|---|---|
| pa_keen_edge | PA | common | any | 3 | +12/20/28 урона атаки |
| pa_veil_step | PA | common | any | 2 | +15/25 скорости |
| pa_dagger_whet | PA | common | any | 2 | −0.6/1.2 с cd Stifling Dagger |
| pa_shadow_guard | PA | common | any | 2 | +3/5 брони |
| pa_bloodletter | PA | rare | physical | 2 | +4/7% шанс native-крита |
| pa_spirit_haste | PA | rare | physical | 2 | −2/4 с cd духа |
| pa_static_edge | PA | rare | magical | 2 | +60/120 урона цепи |
| pa_conductive_blade | PA | epic | magical | 1 | +5% шанс цепи (нужен pa_static_edge) |
| u_vitality | все | common | any | 3 | +150/250/350 HP |
| u_focus | все | common | any | 2 | +120/200 маны |
| u_swift_hands | все | common | any | 3 | +15/25/35 скорости атаки |
| u_arcane_edge | все | common | any | 3 | +6/10/14% усиления заклинаний |
| u_iron_skin | все | common | any | 2 | +2/4 брони |
| u_quick_feet | все | common | any | 2 | +12/20 скорости |
| u_mending | все | common | any | 3 | +4/7/10 регенерации HP |
| u_steadfast | все | rare | any | 2 | +8/14% сопротивления эффектам |

Все числа — HYPOTHESIS. Цель альфы: PA 6c/3r/3e, общих 8c/6r/4e.

## Правила предложений (реализовано, test_offers)
12 предложений по расписанию ACTIVE; 1-е — только common; веса по фазам из конфига; до 3 разных вариантов;
без максимальных рангов, чужих героев, несвоего направления, невыполненных prerequisites и exclusive_group.
До выбора направления — только `any`. Срок 45 с; таймаут → первый ещё допустимый вариант, иначе компенсация.
Выбор идемпотентен; владелец проверяется по PlayerID из контекста движка. Seed серверный, генерация воспроизводима.
