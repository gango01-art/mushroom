# Статус героев и направлений

Статусы: **implemented** (код в движке готов) / **statically_checked** / **runtime_checked** (проверено в Dota) / **blocked**.
Чистая логика с тестами отмечена отдельно — это НЕ runtime-проверка.

| Герой | Направление | Чистая логика (тесты) | Движок | Статус | Блокер |
|---|---|---|---|---|---|
| Phantom Assassin | physical «Призрачная казнь» | pa_physical (3) | verified OP-020/024 | implemented | OP-025 (меню) |
| Phantom Assassin | magical «Грозовые кинжалы» | pa_storm_daggers (12) | verified OP-023 | implemented | OP-025 (урон кинжала) |
| Legion Commander | physical Duel (чемпион) | lc_duel (10) | написан (сессия 22) | planned, ждёт проверки | OP-027 |
| Legion Commander | magical Duel (spell amp) + статуя | lc_magic (4) | нет | следующий шаг | — |
| Shadow Fiend | physical Requiem (сферы) | sf_physical (5) | **да**: sf_requiem_physical, modifier_rift_sf_spheres, native Requiem отключён | statically_checked | OP-016; частицы крыльев/сфер не выбраны |
| Shadow Fiend | magical Requiem (кольца) | sf_magical (4) | **да**: modifier_rift_sf_rings (слушатель Requiem), modifier_rift_sf_fear | statically_checked | OP-017 |
| Templar Assassin | physical Psionic Crystal | ta_physical (5) | **да**: ta_psionic_crystal, ta_meld_physical, блок native spill | **implemented** + runtime_checked (OP-013/015) | мелочи OP-014; путь через меню — OP-018 |
| Templar Assassin | magical Psionic Trap / волны | ta_magical (1) | **да**: ta_refraction_magical, ta_meld_dash, ta_psi_wave, ta_psionic_blast, запрет атак | **implemented** + runtime_checked (OP-015) | обрыв рывка, бафф Q, замедление R, иллюзии — не проверены |

**Templar Assassin — первый герой в выборе с обоими направлениями** (2026-11-12). PA остаётся в herolist как временный
тестовый герой цикла матча без направлений (меню для PA не открывается).

## Порядок реализации в движке (BRIEF_HEROES §13)
TA physical → TA magical → SF physical → SF magical → LC physical → LC magical → UI/локализация.
PA — после OP-004.

Набор TA в текущей версии Dota (OP-013): slot 0 Meld, 1 Psi Blades, 2 Trap, 3 Trap Teleport (скрыт), 4 Psionic Trap (ульта),
5 Inner Peace (врождённая). Refraction в наборе нет.
