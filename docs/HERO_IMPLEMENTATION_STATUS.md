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
| Templar Assassin | physical Psionic Crystal | ta_physical (5) | **да**: ta_psionic_crystal, ta_meld_physical, блок native spill | statically_checked | OP-013 (проверка в Dota) |
| Templar Assassin | magical Psionic Trap / волны | ta_magical (1) | нет | blocked | OP-006 |

Ни один герой не готов для публичного выбора. В herolist только PA — как тестовый герой цикла матча
(без направлений: меню направления не открывается, ядро отклоняет его, пока обе версии не implemented).

## Порядок реализации в движке (BRIEF_HEROES §13)
TA physical → TA magical → SF physical → SF magical → LC physical → LC magical → UI/локализация.
PA — после OP-004.
