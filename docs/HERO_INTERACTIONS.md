# Матрицы взаимодействий (LC / SF / TA)

Статусы: **supported** / **unsupported** / **blocked** / **unknown** (не проверено в движке).
Пока движковая часть не написана и не запускалась, всё ниже — целевая политика, статус `unknown`.

## LC physical — чемпион
| Эффект | Целевая политика | Статус |
|---|---|---|
| Moment of Courage (native) | проверить, можно ли дать чемпиону копию способности с уровнем LC | unknown |
| Lifesteal | лечит чемпиона, не LC | unknown |
| Crit / bash / cleave / armor reduction (предметы) | разрешить проверенные с обычными ICD, без двойного on-hit | unknown |
| Инвентарь | не копируется настоящими предметами | — (правило) |

## SF physical — сферы
| Эффект | Политика | Статус |
|---|---|---|
| Crit | урон сферы от атаки без крит-множителя, без своего броска | правило в ядре; движок unknown |
| Bash / молния / item proc | один шанс на атаку, сфера не даёт второй | unknown |
| Lifesteal | по фактическому урону сферы, без двойного heal | unknown |
| Cleave / multishot / reflect / redirect | проверять отдельно | unknown |
| Талант «урон атаки к Shadowraze» | не складывать с бонусом ветки; нужна замена | unknown |

## SF magical — кольца
| Ситуация | Политика | Статус |
|---|---|---|
| Debuff immunity | 0 урона кольца, 1 короткий fear на каст | ядро ✔, движок unknown |
| Invulnerability | ничего | ядро ✔ |
| Автоматический Requiem при смерти | без колец и без пробивающего fear | unknown |

## TA physical — кристалл (реализация: сессия 10)
Кристалл — юнит нейтральной команды (чтобы его могли атаковать и TA, и враги), урон по нему заблокирован,
HP показывает прочность 3/2/1. Импульс: `ApplyDamage` от TA, тип урона = `GetAbilityDamageType()` Psi Blades
(если NONE — PURE), флаг NO_SPELL_AMPLIFICATION, ability = кристалл; только настоящие вражеские герои,
дедупликация по `ids:victim_key`. Коэффициент = `attack_spill_pct/100` текущего E.
| Эффект | Политика | Статус |
|---|---|---|
| Native spill от удара по кристаллу | блокируется фильтром урона (inflictor Psi Blades в тот же кадр, что удар по кристаллу) | unknown → OP-013 |
| Исходный удар | `params.damage` из OnAttackLanded (ожидается: с Meld/Refraction/критом этой атаки) | unknown → OP-013 |
| Авто-атака кристалла | кристалл нейтральный — TA/враги могут авто-атаковать его, если стоят рядом без цели | известное поведение |
| Meld / Refraction | бонус только к атаке, на которую потрачены | unknown |
| Crit | участвует в исходном hit один раз; pulse без своих бросков | unknown |
| Item on-hit / lifesteal с кристалла | нет | unknown |

## TA magical
| Ситуация | Политика | Статус |
|---|---|---|
| Запрет атак | запрет атак (не 0 AS): приказы, auto-acquire, forced attack | unknown |
| Волны | magic, без attack record/crit/bash/on-hit, spell amp один раз | ядро (дедупликация) ✔ |
| Trap | без суммирования с native trap damage/slow; явная trap_debuff_policy | unknown |
