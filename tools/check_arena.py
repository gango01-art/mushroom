#!/usr/bin/env python3
"""Validate actual Hammer source data, not only its accompanying layout JSON."""
from pathlib import Path
import json
import math
from vendor import datamodel as dm

root = Path(__file__).resolve().parents[1]
model = dm.load(str(root / 'content/maps/rift_arena.vmap'))
layout = json.loads((root / 'content/maps/rift_arena.layout.json').read_text())
children = model.root['world']['children']
entities = {e['entity_properties']['targetname']: e for e in children if e.type == 'CMapEntity'}
for group, count in [('spawns', 12), ('relics', 4)]:
    assert len(layout[group]) == count
    for p in layout[group]:
        assert p['name'] in entities, p['name']
        xyz = entities[p['name']]['origin']
        assert list(xyz) == [p['x'], p['y'], p['z']]
        assert max(abs(p['x']), abs(p['y'])) < 3400
for name in ['rift_center', 'rift_bounds_min', 'rift_bounds_max']:
    assert name in entities, name
teams = {int(e['entity_properties']['teamnumber']) for e in children
         if e.type == 'CMapEntity' and e['entity_properties']['classname'] == 'info_player_start_dota'}
assert teams == {2, 3, 6, 7, 8, 9, 10, 11}, teams
shops = [e for e in children if e.type == 'CMapPrefab']
assert len(shops) == 4
assert all(e['targetMapPath'] == 'maps/prefabs/shop_blacksmith_radiant.vmap' for e in shops)
terrain = next(e for e in children if e.type == 'CMapDotaTileGrid')
layer = terrain['layerData'][0]
assert layer['gridWidth'] == layer['gridHeight'] == 64
assert len(layer['verticesHeight']) == 65 ** 2
assert layer['verticesHeight'][32 * 65 + 32] == 0
assert layer['verticesHeight'][0] == 2
assert any(layer['objectsTreeType'])
assert all(e['entity_properties']['classname'] not in {'npc_dota_fort', 'npc_dota_tower'}
           for e in children if e.type == 'CMapEntity')
# Every spawn is symmetric and outside the central combat/relic area.
for p in layout['spawns']:
    assert abs(math.hypot(p['x'], p['y']) - 3000) < 2
    assert any(abs(q['x'] + p['x']) < 2 and abs(q['y'] + p['y']) < 2 for q in layout['spawns'])
print('Hammer source OK: 12 spawns, 4 relics, 8 teams, 4 shop prefabs, terrain + cover. Compilation/nav NOT tested.')
