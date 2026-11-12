# Сетевой контракт (schema_version 1)

Все net tables публичны — частные данные (предложения улучшений) в них не кладутся.

## Net table `rift_match`
- `state`: `{ schema, version, state, elapsed, remaining, active_total, dev(0/1), map_fallback(0/1), contenders{ "1": pid, ... } }`
  Публикуется ≤ 2 раз/с и сразу при смене стадии.
- `result`: `{ winner (pid или -1), reason }` — один раз при FINISHED.
  reason ∈ score, overtime_first_point, tiebreak_kills, tiebreak_deaths, tiebreak_earlier_score,
  tiebreak_player_order, no_players.

## Net table `rift_scores`
- `board`: `{ rows{ "1": { pid, score, kills, deaths, assists, hero, direction } } }`, отсортировано.

## Custom events
Пока нет. Этап C добавит: клиент→сервер `rift_offer_choose { offer_id, option_id }`
(отправитель — из PlayerID callback-контекста движка, не из payload), сервер→клиент адресно
`rift_offer_update`, запрос снапшота `rift_snapshot_request`.
