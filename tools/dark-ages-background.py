#!/usr/bin/env python3
"""Render the DOOM: The Dark Ages menu background: dark teal stone with a soft vignette (no game art needed).

usage: dark-ages-background.py OUT.jpg [WIDTH HEIGHT]   (default 2560x1440)
"""
import sys, random
from PIL import Image, ImageFilter, ImageDraw, ImageChops

out = sys.argv[1]
W = int(sys.argv[2]) if len(sys.argv) > 2 else 2560
H = int(sys.argv[3]) if len(sys.argv) > 3 else 1440
random.seed(7)

# base: teal gradient, slightly lighter towards the upper right like the in-game menu
base = Image.new("RGB", (W, H))
d = ImageDraw.Draw(base)
for y in range(H):
    t = y / H
    d.line([(0, y), (W, y)], fill=(int(10 - 4 * t), int(34 - 8 * t), int(36 - 8 * t)))

# stone texture: several octaves of blurred noise, multiplied in
def noise(scale, strength):
    small = Image.effect_noise((max(2, W // scale), max(2, H // scale)), 64).convert("L")
    layer = small.resize((W, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(scale / 6))
    return layer.point(lambda v: 128 + int((v - 128) * strength))
tex = Image.new("L", (W, H), 128)
for scale, strength in ((4, 0.18), (12, 0.35), (40, 0.5), (120, 0.6)):
    tex = ImageChops.add(tex, noise(scale, strength), 1.0, -128)
tex = tex.point(lambda v: 90 + v * 0.55)   # keep it dark, low contrast
textured = ImageChops.multiply(base, Image.merge("RGB", (tex, tex, tex))).point(lambda v: min(255, int(v * 1.75)))

# vignette: darker corners, darkest along the bottom
vig = Image.new("L", (W, H), 0)
ImageDraw.Draw(vig).ellipse([-W * 0.25, -H * 0.55, W * 1.15, H * 1.25], fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(W / 5)).point(lambda v: 110 + v * 0.57)
img = ImageChops.multiply(textured, Image.merge("RGB", (vig, vig, vig)))
img.save(out, quality=92)
print(f"{out}: {W}x{H}")
