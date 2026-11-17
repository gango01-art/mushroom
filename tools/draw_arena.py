#!/usr/bin/env python3
"""Render an engineering plan from actual native terrain, not an invented map."""
from pathlib import Path
import json
from vendor import datamodel as dm
ROOT=Path(__file__).resolve().parents[1]
l=json.loads((ROOT/'content/maps/rift_arena.layout.json').read_text(encoding='utf-8'))
m=dm.load(str(ROOT/'content/maps/rift_arena.vmap'))
t=next(e for e in m.elements if e.type=='CMapDotaTileGrid');g=t['layerData'][0]
s=.056;cx=420;cy=400
out=['<svg xmlns="http://www.w3.org/2000/svg" width="840" height="850" viewBox="0 0 840 850">',
'<rect width="840" height="850" fill="#101b23"/>',
'<style>text{font-family:Arial,sans-serif;fill:#e0e8e8}.small{font-size:12px;fill:#a7bac1}</style>',
'<text x="420" y="36" text-anchor="middle" font-size="24" letter-spacing="3">THE VERDANT REACH</text>',
'<text x="420" y="59" text-anchor="middle" class="small">DUALITY · VALVE FOREST SOLO ADAPTATION · SOURCE PLAN</text>',
'<defs><clipPath id="bounds"><rect x="104.6" y="84.6" width="630.8" height="630.8"/></clipPath></defs>',
'<g clip-path="url(#bounds)">']
for y in range(64):
 for x in range(64):
  i=y*65+x;hs=[g['verticesHeight'][i+j] for j in [0,1,65,66]]
  water=any(g['verticesWater'][i+j] for j in [0,1,65,66])
  h=sum(hs)/4
  color='#294d60' if water else ('#263930' if h>=2 else '#718064' if h>=1 else '#496349')
  px=cx+(-8192+x*256)*s;py=cy-(-8192+(y+1)*256)*s
  out.append(f'<rect x="{px:.2f}" y="{py:.2f}" width="{256*s+.15:.2f}" height="{256*s+.15:.2f}" fill="{color}"/>')
for y in range(257):
 for x in range(257):
  if g['objectsTreeType'][y*257+x]:
   out.append(f'<circle cx="{cx+(-8192+x*64)*s:.2f}" cy="{cy-(-8192+y*64)*s:.2f}" r="2" fill="#274332"/>')
for p in l['shops']:
 out.append(f'<rect x="{cx+p["x"]*s-4:.2f}" y="{cy-p["y"]*s-4:.2f}" width="8" height="8" fill="#d9cb98"/>')
for i,p in enumerate(l['spawns']):
 px,py=cx+p['x']*s,cy-p['y']*s
 out.append(f'<circle cx="{px:.2f}" cy="{py:.2f}" r="6" fill="#e4bf78" stroke="#1b2824"/>')
 out.append(f'<text x="{px+9:.2f}" y="{py+4:.2f}" font-size="10">{i+1:02}</text>')
for p in l['relics']:
 px,py=cx+p['x']*s,cy-p['y']*s
 out.append(f'<path d="M {px:.2f},{py-6:.2f} l 6,6 -6,6 -6,-6 Z" fill="#8bdae5"/>')
out+=['</g>',
'<rect x="104.6" y="84.6" width="630.8" height="630.8" fill="none" stroke="#cfb475" stroke-width="2"/>',
'<text x="420" y="742" text-anchor="middle" font-size="14">8 PLAYERS · 12 SAFE-SPAWN CANDIDATES · 4 RELIC SITES · 10 SHOPS</text>',
'<text x="420" y="770" text-anchor="middle" class="small">11264 × 11264 units · native elevation, ramps, river and tree cover retained</text>',
'<text x="420" y="796" text-anchor="middle" class="small">Gold: spawn candidates · Cyan: relic sites · Squares: neutral shops</text>',
'<text x="420" y="822" text-anchor="middle" class="small">Terrain schematic; models, sight blockers and physics need the native playtest.</text>','</svg>']
(ROOT/'docs/design/arena-plan.svg').write_text('\n'.join(out)+'\n',encoding='utf-8')
print('Wrote source-derived docs/design/arena-plan.svg')
