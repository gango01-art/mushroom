# Сторонние материалы

## Основа арены Valve Overthrow

С 2026-11-17 `content/maps/rift_arena.vmap` — изменённая карта **forest_solo** из установленного примера Valve Overthrow для Dota 2 Workshop Tools. Valve выпустила эти исходники как [пример создания Custom Games](https://www.dota2.com/reborn/part2/?l=english). Используются в addon для Dota 2; это материалы Valve, а не полностью оригинальная геометрия DUALITY и не ассет под Apache/MIT.

Исходный `forest_solo.vmap`: SHA256 `003bfe7c7f7d21093543c1ee8bb8bb089ad56cab69d2b8e0799da4a0097b6501`. Оригинал не менялся. Через штатный Create Addon создана копия `duality_map_review`, карта сохранена нынешним Hammer в vmap 40 и обработана `tools/build_arena.py`. Сохранены рельеф, вода, native ramps и деревья; удалена механика Overthrow, добавлены имена контракта Duality и восемь командных стартов. Подробности: [сравнение](ARENA_COMPARISON_2026-11-17.md).

Прежняя геометрическая заготовка Barebones заменена этой основой. Лицензионные файлы Barebones остаются для используемой ниже текстуры и VFX reference: Copyright 2014 BMD, Apache License 2.0, [текст](licenses/Barebones-Apache-2.0.txt), [NOTICE](licenses/Barebones-NOTICE.txt).

## Python DMX

`tools/vendor/datamodel.py`: [BlenderSourceTools / Tom Edwards](https://github.com/Artfunkel/BlenderSourceTools/blob/master/io_scene_valvesource/datamodel.py), MIT License (полный текст в начале файла). Используется только инструментами разработки, не включается в VScript.

Локальные исправления: строки prefix attributes читаются без ещё не созданного string dictionary; UInt8/UInt64 и их массивы сохраняют ширину и тип при binary round trip; пустая строка не превращается в null/element при повторном сохранении; убраны хвостовые пробелы. Авторский генератор арены не изменяет лицензию этого модуля.

## API и штатные ресурсы

Новые вызовы сверены с `@moddota/dota-lua-types` 4.38.2. Декларации — справочник, а не доказательство поведения API в установленной версии Dota. Модели/иконки/частицы/звуки и prefab-пути ссылаются на ресурсы Dota 2; сами игровые ассеты не скопированы в репозиторий.


## Gold VFX reference

`content/materials/duality/lc_gold_glow.tga` — неизменённая `materials/particle/basic_glow.tga` из BMD/barebones указанного выше commit (Apache-2.0). Соответствующий `.vtex` изменён для нового пути. `lc_gold_powershot.vpcf` — отдельный жёлтый trail для линейного projectile; схема/operators основаны на примерах `test_shot.vpcf` / `basic_trail.vpcf` того же репозитория. NOTICE и полный текст лицензии включены в addon-пакет.
