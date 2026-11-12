# Сетевой контракт (schema_version 1)

Все net tables публичны — частные данные (предложения улучшений) в них не кладутся.

## Net table `rift_match`
- `state`: `{ schema, version, state, elapsed, remaining, active_total, dev(0/1), map_fallback(0/1), contenders{ "1": pid, ... } }`
  Публикуется ≤ 2 раз/с и сразу при смене стадии.
- `result`: `{ winner (pid или -1), reason }` — один раз при FINISHED.
  reason ∈ score, overtime_first_point, tiebreak_kills, tiebreak_deaths, tiebreak_earlier_score,
  tiebreak_player_order, no_players.

- `relic`: `{ state: idle|warned|ground|carried, carrier (pid|-1), point (1..4|-1), x, y, remaining, budget_left,
  next_point_in, next_event_in (-1 если событий больше нет) }` — публичное, ≤ 2 раз/с.

## Net table `rift_scores`
- `board`: `{ rows{ "1": { pid, score, kills, deaths, assists, hero, direction } } }`, отсортировано.

## Custom events (schema_version 1)
Отправитель client→server определяется только по `PlayerID`, который движок добавляет в args callback.
Массивы передаются объектами с ключами "1".."n".

| Событие | Направление | Payload | Ограничения |
|---|---|---|---|
| `rift_offer_choose` | client → server | `{ offer_id:number, option_id:string }` | id ≤ 64 символов; ≥ 0.1 с между запросами игрока; после FINISHED отклоняется |
| `rift_private_request` | client → server | `{}` | ответ — `rift_private_state` только этому игроку |
| `rift_private_state` | server → один игрок | `{ schema, direction, direction_id, visible_offer, pending{…}, build{…} }` | приватно; отправляется при каждом изменении его предложений/сборки |
| `rift_offer_result` | server → один игрок | `{ offer_id, ok(0/1), reason }` | после каждого `rift_offer_choose` |

`pending[i]`: `{ id, type: regular|ultimate_direction|compensation, remaining(сек), options{…} }`.
`options[i]`: `{ id, kind: upgrade|direction|compensation, rarity?, direction?, loc_name, loc_desc, icon,
rank_now?, rank_next?, max_rank?, required_direction?, values{ key: number }, is_default(0/1) }`.
Тексты карточек — ключи локализации с `{key}`; числа приходят в `values` (не дублируются в UI).
`build[i]`: `{ id, rank, max_rank, loc_name, icon, values }`.

### Reason codes `rift_offer_result`
ok, unknown_offer, not_owner, already_resolved, expired, invalid_option, not_allowed, match_finished, bad_payload.
