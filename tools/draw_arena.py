#!/usr/bin/env python3
"""Export the authored arena layout as a standalone SVG design plan."""
from pathlib import Path
import json
import math
ROOT=Path(__file__).resolve().parents[1]
layout=json.loads((ROOT/'content/maps/rift_arena.layout.json').read_text())
scale=.085
size=840
cx,cy=420,400
def xy(x,y):return cx+x*scale,cy-y*scale
def circle(x,y,r,color,extra=''):
 x,y=xy(x,y);return f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{r*scale:.2f}" fill="{color}" {extra}/>'
items=['<svg xmlns="http://www.w3.org/2000/svg" width="840" height="850" viewBox="0 0 840 850">', '<rect width="840" height="850" fill="#101a28"/>', '<style>text{font-family:Arial,sans-serif;fill:#d7e0ea} .title{font-size:24px;letter-spacing:3px}.small{font-size:12px;fill:#92a5bb}</style>', '<text x="420" y="36" text-anchor="middle" class="title">THE SUNDERED CONCOURSE</text>', '<text x="420" y="59" text-anchor="middle" class="small">DUALITY · ALPHA ARENA / HAMMER SOURCE PLAN</text>']
x,y=xy(-3584,3584)
items.append(f'<rect x="{x}" y="{y}" width="{7168*scale}" height="{7168*scale}" rx="10" fill="#1d2c3b" stroke="#c6a66b" stroke-width="4"/>')
for r in [1500,2450]:items.append(circle(0,0,r,'none','stroke="#526578" stroke-width="1" stroke-dasharray="5 8"'))
items.append(circle(0,0,900,'#2a4955','stroke="#80c8cf" stroke-width="2"'))
items.append('<text x="420" y="405" text-anchor="middle" font-size="17">OPEN CENTRE</text>')
for tx,ty in layout['cover']:items.append(circle(tx,ty,65,'#42695e','stroke="#80a092" stroke-width="1"'))
for i,p in enumerate(layout['spawns']):
 items.append(circle(p['x'],p['y'],90,'#e4c080'))
 x,y=xy(p['x'],p['y']);items.append(f'<text x="{x}" y="{y+4}" text-anchor="middle" font-size="10" fill="#182333">{i+1:02}</text>')
for i,p in enumerate(layout['relics']):
 items.append(circle(p['x'],p['y'],100,'#7ed7df','stroke="#caedef" stroke-width="2"'))
 x,y=xy(p['x'],p['y']);items.append(f'<text x="{x+13}" y="{y+4}" class="small">R{i+1}</text>')
for i,(x,y) in enumerate([(-2304,-2304),(2304,-2304),(2304,2304),(-2304,2304)]):
 x,y=xy(x,y);items.append(f'<rect x="{x-15}" y="{y-12}" width="30" height="24" fill="#a78b62" stroke="#e8cc9a"/>')
items.extend(['<text x="420" y="738" text-anchor="middle" font-size="14">12 SPAWNS · 4 RELIC SITES · 4 SHOPS · 8 COVER CLUSTERS</text>', '<text x="420" y="763" text-anchor="middle" class="small">7168 × 7168 units · spawn radius 3000 · central clearing radius 900</text>', '<text x="420" y="793" text-anchor="middle" class="small">Gold: spawns / shops · Cyan: relic sites · Green: destructible tree cover</text>', '<text x="420" y="818" text-anchor="middle" class="small">Design plan, not a gameplay screenshot. Terrain/nav compilation still requires Workshop Tools.</text>', '</svg>'])
(ROOT/'docs/design/arena-plan.svg').write_text('\n'.join(items)+'\n')
print('Wrote docs/design/arena-plan.svg')
