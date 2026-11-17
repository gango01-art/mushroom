#!/usr/bin/env python3
"""Check the authored map contract and preservation of the native terrain."""
from pathlib import Path
import json
import math
import hashlib
import struct
from vendor import datamodel as dm
from build_arena import terrain_digest, outer_terrain_digest, FLAT_RADIUS, FLAT_LEVEL, SOURCE_OUTER_TERRAIN_SHA256
import sys

root=Path(__file__).resolve().parents[1]
model=dm.load(str(root/'content/maps/rift_arena.vmap'))
layout=json.loads((root/'content/maps/rift_arena.layout.json').read_text(encoding='utf-8'))
assert model.format_ver>=40
nodes=[]
def walk(e):
    nodes.append(e)
    for c in e.get('children',[]): walk(c)
walk(model.root['world'])
entities={e['entity_properties'].get('targetname',''):e for e in nodes if e.type=='CMapEntity'}
for group,count in [('spawns',12),('relics',4)]:
    assert len(layout[group])==count
    for p in layout[group]:
        assert list(entities[p['name']]['origin'])==[p['x'],p['y'],p['z']]
        assert max(abs(p['x']),abs(p['y']))<5400
for name in ['rift_center','rift_bounds_min','rift_bounds_max']:
    assert name in entities
classes=[e['entity_properties']['classname'] for e in nodes if e.type=='CMapEntity']
assert classes.count('ent_dota_game_events')==1
assert not set(classes)&{'npc_dota_base','npc_dota_tower','ent_dota_fountain','dota_custom_game_events','info_particle_system','npc_dota_scripted_spawner'}
starts=[e for e in nodes if e.type=='CMapEntity' and e['entity_properties']['classname']=='info_player_start_dota']
assert len(starts)==8
assert {int(e['entity_properties']['teamnumber']) for e in starts}=={2,3,6,7,8,9,10,11}
prefabs=[e for e in nodes if e.type=='CMapPrefab']
assert all(e['targetMapPath'] in {'maps/prefabs/shop_sithil.vmap','maps/prefabs/rune_base.vmap'} for e in prefabs)
assert sum(e['targetMapPath']=='maps/prefabs/shop_sithil.vmap' for e in prefabs)==10
assert len(layout['shops'])==10
for base in layout['bases']:
    assert min(math.hypot(base['x']-s['x'],base['y']-s['y']) for s in layout['shops'])>=192
    for p in [base,base['tower']]:
        assert list(entities[p['name']]['origin'])==[p['x'],p['y'],p['z']]
assert {b['team'] for b in layout['bases']}=={2,3,6,7,8,9,10,11}
layer=next(e for e in nodes if e.type=='CMapDotaTileGrid')['layerData'][0]
assert layer['gridWidth']==layer['gridHeight']==64
for key,n in [('verticesHeight',65**2),('verticesWater',65**2),('edgesPath',2*64*65),('gridnavFlags',64*64*16)]:
    assert len(layer[key])==n,(key,len(layer[key]),n)
cache=layer['cellConfiguration'];cursor=0
for _ in range(64*64):
    assert cursor<len(cache),'Truncated packed terrain cache'
    count=cache[cursor];assert count>=0
    cursor+=count+1
assert cursor==len(cache)
assert terrain_digest(layer)==layout['terrain_sha256'],'Terrain digest mismatch'
assert layout['revision']==2
assert outer_terrain_digest(layer)==layout['outer_terrain_sha256']==SOURCE_OUTER_TERRAIN_SHA256,'Unrelated outer terrain/navigation changed'
for i,h in enumerate(layer['verticesHeight']):
    if math.hypot(-8192+(i%65)*256,-8192+(i//65)*256)<=FLAT_RADIUS:
        assert h==FLAT_LEVEL and not layer['verticesWater'][i], 'Combat ground must be flat and dry'
for e in nodes:
    if e.type=='CMapMesh' and math.hypot(*list(e['origin'])[:2])<512:
        assert 'materials/tools/toolsskip.vmat' not in e['meshData']['materials'],'Invisible center collision returned'
assert sum(layer['edgesPath'])==101
assert layout['bounds']==[-5632,-5632,5632,5632]
if '--geometry-only' not in sys.argv:
    assert layout.get('overview_map_sha256')==hashlib.sha256((root/'content/maps/rift_arena.vmap').read_bytes()).hexdigest(), 'Regenerate the native minimap after editing geometry'
header=(root/'content/materials/overviews/rift_arena.tga').read_bytes()[:18]
assert struct.unpack_from('<HH',header,12)==(512,512)
assert 'materials/overviews/rift_arena.tga' in (root/'content/materials/overviews/rift_arena.vmat').read_text()
assert 'scale 11.000' in (root/'game/resource/overviews/rift_arena.txt').read_text()
print('Hammer source OK: flat combat circle, center skip-solid removed, eight sanctuary/tower anchors; outer terrain preserved. Native compile/nav is a separate check.'+(' Minimap verification skipped.' if '--geometry-only' in sys.argv else ''))
