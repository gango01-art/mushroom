# Сторонние материалы

## Terrain-шаблон Barebones

`content/maps/rift_arena.vmap` содержит изменённую основу Terrain и настройки освещения из `template_map.vmap` проекта [BMD / barebones](https://github.com/bmddota/barebones), commit `873bcb971c127a9babd36afb3f27d6aeeb20d25f`.

Copyright 2014 BMD. Apache License 2.0: [текст](licenses/Barebones-Apache-2.0.txt), [NOTICE](licenses/Barebones-NOTICE.txt).

Изменения DUALITY: край арены, расстановка деревьев, цветовой план, старты восьми команд, 12 spawn/4 relic/center/bounds, четыре штатных shop-prefab; старые стартовые группы удалены из world children. Это исходник карты для дополнительной сборки и проверки в текущем Hammer.

## Python DMX

`tools/vendor/datamodel.py`: [BlenderSourceTools / Tom Edwards](https://github.com/Artfunkel/BlenderSourceTools/blob/master/io_scene_valvesource/datamodel.py), MIT License (полный текст в начале файла). Используется только инструментами разработки, не включается в VScript.

Локальные исправления: строки prefix attributes читаются без ещё не созданного string dictionary; UInt8/UInt64 и их массивы сохраняют ширину и тип при binary round trip; убраны хвостовые пробелы. Авторский генератор арены не изменяет лицензию этого модуля.

## API и штатные ресурсы

Новые вызовы сверены с `@moddota/dota-lua-types` 4.38.2. Декларации — справочник, а не доказательство поведения API в установленной версии Dota. Модели/иконки/частицы/звуки и prefab-пути ссылаются на ресурсы Dota 2; сами игровые ассеты не скопированы в репозиторий.


## Gold VFX reference

`content/materials/duality/lc_gold_glow.tga` — неизменённая `materials/particle/basic_glow.tga` из BMD/barebones указанного выше commit (Apache-2.0). Соответствующий `.vtex` изменён для нового пути. `lc_gold_powershot.vpcf` — отдельный жёлтый trail для линейного projectile; схема/operators основаны на примерах `test_shot.vpcf` / `basic_trail.vpcf` того же репозитория. NOTICE и полный текст лицензии включены в addon-пакет.
