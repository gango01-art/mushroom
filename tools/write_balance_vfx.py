"""Build the SF overhead charge glyph (no hero models or borrowed emblems)."""
from pathlib import Path
import math
import struct
root = Path(__file__).resolve().parents[1] / "content/materials/duality"
width, height = 64, 96
pixels = bytearray()
for y in range(height):
    for x in range(width):
        # Tall, leaning ember shard; warm core, crimson edge, soft antialiasing.
        v = (y + .5) / height * 2 - 1
        u = ((x + .5) / width * 2 - 1) - .25 * v
        edge = 1 - abs(u) / .68 - abs(v) / .92
        alpha = max(0, min(1, edge * 18))
        core = max(0, min(1, edge * 2.6))
        r, g, b = 255, int(65 + 185 * core), int(8 + 160 * core**3)
        pixels.extend((b, g, r, int(alpha * 255)))
header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, width, height, 32, 0x28)
(root / "sf_charge.tga").write_bytes(header + pixels)
source = (root / "lc_gold_glow.vtex").read_text(encoding="utf-8")
(root / "sf_charge.vtex").write_text(source.replace("lc_gold_glow.tga", "sf_charge.tga"), encoding="utf-8")
print("SF ember charge texture generated: 64 x 96 RGBA")
