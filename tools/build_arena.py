#!/usr/bin/env python3
"""Author rift_arena.vmap from BMD's Apache-2.0 Source 2 terrain template.

Usage: python3 tools/build_arena.py --template template_map.vmap --datamodel datamodel.py
Inputs/provenance: docs/ARENA_BUILD.md. Does not compile a map or run Workshop Tools.
No third-party runtime dependency: the DMX adapter is used at authoring time only.
"""
import argparse
import importlib.util
import json
import math
from pathlib import Path
import uuid

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--template', type=Path, required=True)
    parser.add_argument('--datamodel', type=Path, default=ROOT / 'tools/vendor/datamodel.py')
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location('map_datamodel', args.datamodel)
    dm = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(dm)
    model = dm.load(str(args.template))
    world = model.root['world']
    tile = next(e for e in model.elements if e.type == 'CMapDotaTileGrid')
    layer = tile['layerData'][0]
    assert layer['gridWidth'] == layer['gridHeight'] == 64
    # Keep the documented, native 64x64 terrain/grid schema intact.
    # The playable square is the central 7168 units; cliffs form its outer rim.
    for y in range(65):
        for x in range(65):
            px, py = -8192 + x * 256, -8192 + y * 256
            layer['verticesHeight'][y * 65 + x] = 0 if max(abs(px), abs(py)) <= 3584 else 2
    trees = []
    for i in range(8):
        angle = math.radians(22.5 + i * 45)
        for offset in (-128, 0, 128):
            trees.append((1450 * math.cos(angle) - offset * math.sin(angle),
                          1450 * math.sin(angle) + offset * math.cos(angle)))
    # Objects occupy a 64-unit subgrid. Short three-tree copses preserve two
    # routes around every cover location. No forest in spawn or relic pockets.
    for y in range(257):
        for x in range(257):
            idx = y * 257 + x
            px, py = -8192 + x * 64, -8192 + y * 64
            is_tree = any((px - tx) ** 2 + (py - ty) ** 2 < 38 ** 2 for tx, ty in trees)
            layer['objectsTreeType'][idx] = 1 if is_tree else 0
            layer['objectsTreeSize'][idx] = 1 if is_tree else 0
            layer['objectsRotation'][idx] = (x * 37 + y * 13) % 360 if is_tree else 0
            layer['objectsPitch'][idx] = 0
            layer['objectsVariationId'][idx] = dm.UInt8(0 if is_tree else 255)
    # A subtle warm/cool split; the centre stays bright and readable.
    for y in range(513):
        for x in range(513):
            px, py = -8192 + x * 32, -8192 + y * 32
            central = math.hypot(px, py) < 900
            color = [245, 236, 216, 0] if central else ([245, 220, 195, 0] if px < 0 else [195, 227, 245, 0])
            layer['blendColor'][y * 513 + x] = dm.Color(color)
    # Strip the tutorial's starts/groups, preserving only terrain and lighting.
    keep = [tile]
    keep_classes = {'env_global_light', 'env_wind', 'ent_dota_game_events',
                    'water_lod_control', 'env_tonemap_controller', 'env_fog_controller', 'ent_dota_lightinfo'}
    for e in model.elements:
        if e.type == 'CMapEntity' and e['entity_properties']['classname'] in keep_classes:
            keep.append(e)
    world['children'] = dm.make_array(keep, dm.Element)
    node = 100
    layout = {'name': 'The Sundered Concourse', 'bounds': [-3584, -3584, 3584, 3584],
              'floor_z': 128, 'spawns': [], 'relics': [], 'cover': trees, 'starts': []}
    def entity(classname, name, x, y, z=160, extra=None):
        nonlocal node
        node += 1
        e = model.add_element(name, 'CMapEntity', id=uuid.uuid5(uuid.NAMESPACE_URL, 'duality/entity/' + name))
        e['origin'], e['angles'], e['scales'] = dm.Vector3([x, y, z]), dm.Angle([0, 0, 0]), dm.Vector3([1, 1, 1])
        e['nodeID'], e['referenceID'] = node, dm.UInt64(0)
        e['children'] = dm.make_array([], dm.Element)
        e['editorOnly'], e['force_hidden'], e['isProceduralEntity'] = False, False, False
        e['variableTargetKeys'], e['variableNames'] = dm.make_array([], str), dm.make_array([], str)
        e['hitNormal'] = dm.Vector3([0, 0, 1])
        props = model.add_element(name + '_properties', 'EditGameClassProps', id=uuid.uuid5(uuid.NAMESPACE_URL, 'duality/props/' + name))
        props['classname'], props['targetname'] = classname, name
        for k, v in (extra or {}).items(): props[k] = str(v)
        e['entity_properties'] = props
        world['children'].append(e)
    for i in range(12):
        a = math.radians(60 - i * 30)
        x, y = round(3000 * math.cos(a)), round(3000 * math.sin(a))
        name = f'rift_spawn_{i + 1:02}'
        layout['spawns'].append({'name': name, 'x': x, 'y': y, 'z': 160})
        entity('info_target', name, x, y)
    for i in range(4):
        a = math.radians(45 + i * 90)
        x, y = round(1500 * math.cos(a)), round(1500 * math.sin(a))
        name = f'rift_relic_{i + 1:02}'
        layout['relics'].append({'name': name, 'x': x, 'y': y, 'z': 160})
        entity('info_target', name, x, y)
    entity('info_target', 'rift_center', 0, 0)
    entity('info_target', 'rift_bounds_min', -3584, -3584)
    entity('info_target', 'rift_bounds_max', 3584, 3584)
    for i, team in enumerate([2, 3, 6, 7, 8, 9, 10, 11]):
        p = layout['spawns'][int(i * 12 / 8)]
        layout['starts'].append({'team': team, 'x': p['x'], 'y': p['y']})
        # Class/property are present in BMD's Hammer-authored template.
        entity('info_player_start_dota', f'rift_team_start_{team}', p['x'], p['y'], extra={'teamnumber': team, 'Disabled': 0})
    entity('info_player_start', 'rift_editor_camera', 0, -2200, 600, {'spawnflags': 1})
    # Native Side-shop prefabs (also used by BMD's playground) provide real
    # shop volumes. Universal shop mode exposes all items at these four shops.
    for i, (x, y) in enumerate([(-2304, -2304), (2304, -2304), (2304, 2304), (-2304, 2304)]):
        name = f'rift_shop_{i + 1}'
        node += 1
        e = model.add_element(name, 'CMapPrefab', id=uuid.uuid5(uuid.NAMESPACE_URL, 'duality/prefab/' + name))
        e['origin'], e['angles'], e['scales'] = dm.Vector3([x, y, 128]), dm.Angle([0, 45 + i * 90, 0]), dm.Vector3([1, 1, 1])
        e['nodeID'], e['referenceID'] = node, dm.UInt64(0)
        e['children'] = dm.make_array([], dm.Element)
        e['editorOnly'], e['force_hidden'] = False, False
        e['variableTargetKeys'], e['variableNames'] = dm.make_array([], str), dm.make_array([], str)
        e['targetMapPath'] = 'maps/prefabs/shop_blacksmith_radiant.vmap'
        e['variableOverrideNames'] = dm.make_array(['Shop Type'], str)
        e['variableOverrideValues'] = dm.make_array(['Side'], str)
        e['loadIfNested'], e['loadAtRuntime'], e['fixupEntityNames'] = True, False, True
        e['displayColor'] = dm.Color([128, 192, 200, 255])
        world['children'].append(e)
        # Remove embedded thumbnail prefix data and unused nodes via the DMX writer.
    model.prefix_attributes.clear()
    out = ROOT / 'content/maps/rift_arena.vmap'
    data = model.echo('binary', 9)
    temporary = out.with_suffix('.vmap.tmp')
    temporary.write_bytes(data)
    temporary.replace(out)
    (ROOT / 'content/maps/rift_arena.layout.json').write_text(json.dumps(layout, indent=2) + '\n')
    print(f'Wrote {out} ({out.stat().st_size} bytes). Open and rebuild tiles/nav in Hammer before compiling.')

if __name__ == '__main__': main()
