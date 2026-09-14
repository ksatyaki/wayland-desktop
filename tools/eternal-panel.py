#!/usr/bin/env python3
"""Render a DOOM Eternal style chamfered panel to a PNG (used by hyprlock, which can only draw rectangles).

usage: eternal-panel.py OUT.png WIDTH HEIGHT [--fill RRGGBBAA] [--border RRGGBBAA] [--cut tlx,tly,trx,try,brx,bry,blx,bly]
Sizes are in logical pixels; the PNG is rendered at 2x for crisp edges (set hyprlock `size` to HEIGHT).
The default cut is the Eternal main-menu shape: straight left edge, slanted right edge, accent line along the bottom.
"""
import argparse
from PIL import Image, ImageDraw

SS = 4   # supersampling for anti-aliased edges
SCALE = 2

def rgba(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4)) + ((int(s[6:8], 16),) if len(s) == 8 else (255,))

ap = argparse.ArgumentParser()
ap.add_argument("out"); ap.add_argument("width", type=int); ap.add_argument("height", type=int)
ap.add_argument("--fill", default="2f3d16d9"); ap.add_argument("--border", default="a9d43aff")
ap.add_argument("--border-width", type=float, default=2)
ap.add_argument("--cut", default=None, help="tlx,tly,trx,try,brx,bry,blx,bly (logical px)")
ap.add_argument("--no-line", action="store_true")
a = ap.parse_args()

W, H = a.width * SCALE * SS, a.height * SCALE * SS
bw = a.border_width * SCALE * SS
if a.cut:
    tlx, tly, trx, try_, brx, bry, blx, bly = [float(v) * SCALE * SS for v in a.cut.split(",")]
else:
    tlx = tly = brx = bry = blx = bly = 0
    trx, try_ = 0.9 * H, H
i = bw / 2
w, h = W - bw, H - bw
poly = [(i + tlx, i), (i + w - trx, i), (i + w, i + try_), (i + w, i + h - bry),
        (i + w - brx, i + h), (i + blx, i + h), (i, i + h - bly), (i, i + tly)]

img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.polygon(poly, fill=rgba(a.fill), outline=rgba(a.border), width=int(bw))
if not a.no_line:
    y = i + h - 3 * bw
    d.line([(i + max(blx, 6 * SCALE * SS) + 4 * SCALE * SS, y), (i + w - max(brx, 6 * SCALE * SS) - 4 * SCALE * SS, y)],
           fill=rgba(a.border), width=int(bw))
img = img.resize((W // SS, H // SS), Image.LANCZOS)
img.save(a.out)
print(f"{a.out}: {img.size[0]}x{img.size[1]} px (logical {a.width}x{a.height})")
