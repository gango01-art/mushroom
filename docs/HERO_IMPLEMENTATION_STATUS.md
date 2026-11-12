# Статус героев и направлений

Статусы: **implemented** (код в движке готов) / **statically_checked** / **runtime_checked** (проверено в Dota) / **blocked**.
Чистая логика с тестами отмечена отдельно — это НЕ runtime-проверка.

| Герой | Направление | Чистая логика (тесты) | Движок | Статус | Блокер |
|---|---|---|---|---|---|
| Phantom Assassin | physical «Призрачная казнь» | — | нет | blocked | OP-004 (native-значения Coup de Grace) |
| Phantom Assassin | magical «Грозовые кинжалы» | pa_storm_daggers (10) | нет | blocked | OP-004 |
| Legion Commander | physical Duel (чемпион) | lc_duel (10) | нет | blocked | OP-006 (способности LC), ассеты трона/воина |
| Legion Commander | magical Duel (spell amp) + статуя | lc_magic (4) | нет | blocked | OP-006 |
| Shadow Fiend | physical Requiem (сферы) | sf_physical (5) | нет | blocked | OP-006, проверка attack record API |
| Shadow Fiend | magical Requiem (кольца) | sf_magical (4) | нет | blocked | OP-006, политика fear через debuff immunity |
| Templar Assassin | physical Psionic Crystal | ta_physical (5) | **да**: ta_psionic_crystal, ta_meld_physical, блок native spill | runtime_checked (основное, OP-013) | мелочи OP-014; в выбор — только вместе с магической веткой |
| Templar Assassin | magical Psionic Trap / волны | ta_magical (1) | **да**: ta_refraction_magical, ta_meld_dash, ta_psi_wave, ta_psionic_blast, запрет атак | statically_checked | OP-015 |

Ни один герой не готов для публичного выбора. В herolist только PA — как тестовый герой цикла матча
(без направлений: меню направления не открывается, ядро отклоняет его, пока обе версии не implemented).

## Порядок реализации в движке (BRIEF_HEROES §13)
TA physical → TA magical → SF physical → SF magical → LC physical → LC magical → UI/локализация.
PA — после OP-004.

Набор TA в текущей версии Dota (OP-013): slot 0 Meld, 1 Psi Blades, 2 Trap, 3 Trap Teleport (скрыт), 4 Psionic Trap (ульта),
5 Inner Peace (врождённая). Refraction в наборе нет.
