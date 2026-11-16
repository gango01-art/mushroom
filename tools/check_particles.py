#!/usr/bin/env python3
"""Check custom VFX source links/palette/budgets. Does not replace ResourceCompiler."""
from pathlib import Path
import re
import struct
ROOT=Path(__file__).resolve().parents[1]
particle=ROOT/'content/particles/duality/lc_gold_powershot.vpcf'
text=particle.read_text()
assert text.startswith('<!-- kv3 encoding:text:'), 'Particle source header'
assert text.count('{')==text.count('}') and text.count('[')==text.count(']'), 'Unbalanced particle source'
texture=re.search(r'm_hTexture\s*=\s*resource:"([^"]+)"',text).group(1)
vtex=ROOT/'content'/texture
assert vtex.is_file(), texture
image=re.search(r'"m_fileName"\s+"string"\s+"([^"]+)"',vtex.read_text()).group(1)
tga=ROOT/'content'/image
assert tga.is_file(), image
header=tga.read_bytes()[:18]
width,height=struct.unpack_from('<HH',header,12)
assert width>0 and height>0 and header[16] in (24,32), 'Invalid TGA dimensions/depth'
color=[int(n) for n in re.search(r'm_ConstantColor\s*=\s*\[([^]]+)\]',text).group(1).split(',')]
assert color[0]>=200 and color[1]>=170 and color[2]<=80, 'Yellow palette'
assert 'particles/duality/lc_gold_powershot.vpcf' in (ROOT/'game/scripts/vscripts/rift/data/hero_balance.lua').read_text()
assert float(re.search(r'm_flConstantLifespan\s*=\s*([\d.]+)',text).group(1))<1
assert int(re.search(r'm_nMaxParticles\s*=\s*(\d+)',text).group(1))<=128
print('Custom yellow VFX source OK: particle -> texture -> TGA, palette/lifetime/budget. Source 2 compile/render NOT tested.')
for name in ('lc_gold_powershot',):
    source=(ROOT/'content/particles/duality'/f'{name}.vpcf').read_text()
    assert '36c3961f-02a4-4c52-bf8f-6e3147d7d142' in source, f'{name}: structured float inputs require the modern format; legacy migration zeros emission'
    assert re.search(r'm_flLiteralValue\s*=\s*(?:1|32)\.0',source), f'{name}: positive instantaneous emission'
