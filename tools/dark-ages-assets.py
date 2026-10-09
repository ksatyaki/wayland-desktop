#!/usr/bin/env python3
"""Render the PNG pieces of the DOOM: The Dark Ages desktop theme (themes/dark-ages/ in the repo).

Waybar (GTK CSS) and hyprlock can only draw rectangles, so the spear-tipped menu bars and the stone
texture of the Dark Ages menus are images. The shapes follow sddm-dark-ages-theme's DarkAgesBar.qml.

usage: dark-ages-assets.py stone OUT.png WIDTH HEIGHT [--alpha 0.88]
           Teal stone strip, seamless when repeated horizontally (bar background).
       dark-ages-assets.py bar OUT.png WIDTH HEIGHT [--fill RRGGBBAA] [--border RRGGBBAA] [--tip PX] [--scale N] [--mid MID.png]
           Spear-tipped bar: a glow at both tips fading into the fill, a thin outline and a soft inner outline.
           --mid also writes the bar's centre column (Waybar stretches it between the 9-sliced tips).
       dark-ages-assets.py rule OUT.png WIDTH HEIGHT [--color RRGGBBAA] [--star] [--scale N]
           Hairline fading out towards both ends, optionally with a four-pointed star at each end.
Sizes are logical pixels; --scale renders at a multiple of that (2 for HiDPI; set the CSS/hyprlock size to the
logical values). The spear tip is `--tip` logical pixels long (default 0.6 x height, like the game).
"""
import argparse, random
from PIL import Image, ImageDraw, ImageFilter, ImageChops

SS = 4   # supersampling for anti-aliased edges


def rgba(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4)) + ((int(s[6:8], 16),) if len(s) == 8 else (255,))


def with_alpha(c, a):
    return c[:3] + (int(round(c[3] * a)),)


def stone(a):
    random.seed(7)
    W, H, ov = a.width, a.height, min(128, a.width // 4)
    Wg = W + ov                       # render wider, then crossfade the overlap so the strip tiles
    # base: dark teal, a touch lighter towards the top like the lit stone of the in-game menu frame
    base = Image.new("RGB", (Wg, H))
    d = ImageDraw.Draw(base)
    for y in range(H):
        t = y / max(1, H - 1)
        d.line([(0, y), (Wg, y)], fill=(int(13 - 4 * t), int(38 - 9 * t), int(40 - 9 * t)))

    def noise(scale, strength):
        small = Image.effect_noise((max(2, Wg // scale), max(2, H // scale)), 64).convert("L")
        layer = small.resize((Wg, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(scale / 6))
        return layer.point(lambda v: 128 + int((v - 128) * strength))
    tex = Image.new("L", (Wg, H), 128)
    for scale, strength in ((2, 0.25), (5, 0.45), (12, 0.4), (40, 0.3)):
        tex = ImageChops.add(tex, noise(scale, strength), 1.0, -128)
    tex = tex.point(lambda v: 95 + v * 0.5)
    img = ImageChops.multiply(base, Image.merge("RGB", (tex, tex, tex))).point(lambda v: min(255, int(v * 1.7)))
    # seamless: blend the last `ov` columns over the first ones with a linear ramp
    left = img.crop((0, 0, ov, H)); right = img.crop((W, 0, Wg, H))
    ramp = Image.linear_gradient("L").rotate(90, expand=True).resize((ov, H))   # 0 at left .. 255 at right
    img.paste(Image.composite(left, right, ramp), (0, 0))
    img = img.crop((0, 0, W, H))
    # alpha: mostly opaque, the texture shows a little of what is behind (blurred by the compositor)
    alpha = tex.crop((0, 0, W, H)).point(lambda v: int(255 * a.alpha * (0.9 + 0.1 * v / 255)))
    img.putalpha(alpha)
    img.save(a.out)
    print(f"{a.out}: {W}x{H}, alpha {a.alpha}")


def spear(w, h, tip, inset):
    """Spear-tipped bar outline, inset by `inset` on every side (tip shortened proportionally)."""
    i = inset
    t = tip - i * 0.6
    return [(i + t, i), (w - i - t, i), (w - i, h / 2), (w - i - t, h - i), (i + t, h - i), (i, h / 2)]


def bar(a):
    S = a.scale * SS
    W, H = int(a.width * S), int(a.height * S)
    tip = (a.tip if a.tip else 0.6 * a.height) * S
    bw = a.border_width * S
    fill, border = rgba(a.fill), rgba(a.border)

    # fill: horizontal gradient, the border colour glowing at the tips (QML: 55 % at 0 and 1, fill at 0.12 and 0.88)
    grad = Image.new("RGBA", (W, H))
    gd = ImageDraw.Draw(grad)
    glow = with_alpha(border, 0.55)
    for x in range(W):
        p = x / max(1, W - 1)
        if p < 0.12:
            k = p / 0.12
        elif p > 0.88:
            k = (1 - p) / 0.12
        else:
            k = 1.0
        c = tuple(int(round(glow[j] + (fill[j] - glow[j]) * k)) for j in range(4))
        gd.line([(x, 0), (x, H)], fill=c)
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).polygon(spear(W, H, tip, bw / 2), fill=255)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    img.paste(grad, (0, 0), mask)

    d = ImageDraw.Draw(img)
    # outline
    d.polygon(spear(W, H, tip, bw / 2), outline=border, width=max(1, int(bw)))
    # soft inner outline (QML: 35 % alpha, 3 px, 4 px inside)
    inner = max(2.0, a.height / 9) * S
    d.polygon(spear(W, H, tip, inner), outline=with_alpha(border, 0.35), width=max(1, int(bw * 1.5)))
    img = img.resize((W // SS, H // SS), Image.LANCZOS)
    img.save(a.out)
    print(f"{a.out}: {img.size[0]}x{img.size[1]} px (logical {a.width}x{a.height}, scale {a.scale})")
    if a.mid:
        # the centre column, for GTK: border-image draws only the sliced edges (no `fill`), so the
        # stretched middle of the bar comes from this strip as background-image
        x = img.size[0] // 2
        img.crop((x, 0, x + 2, img.size[1])).save(a.mid)
        print(f"{a.mid}: centre strip")


def rule(a):
    S = a.scale * SS
    W, H = int(a.width * S), int(a.height * S)
    color = rgba(a.color)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    y = H / 2
    lw = max(1, int(a.line_width * S))
    star = a.height / 2 * S if a.star else 0
    x0, x1 = star * 1.6, W - star * 1.6
    # line fading towards both ends
    for x in range(int(x0), int(x1)):
        p = (x - x0) / max(1, x1 - x0)
        k = min(1.0, min(p, 1 - p) / 0.25)        # fade over the outer quarter
        d.line([(x, y), (x, y + lw)], fill=with_alpha(color, 0.25 + 0.75 * k))
    if a.star:
        for cx in (star, W - star):
            r, s = star, star * 0.22
            d.polygon([(cx, y - r), (cx + s, y - s), (cx + r, y), (cx + s, y + s),
                       (cx, y + r), (cx - s, y + s), (cx - r, y), (cx - s, y - s)], fill=color)
    img = img.resize((W // SS, H // SS), Image.LANCZOS)
    img.save(a.out)
    print(f"{a.out}: {img.size[0]}x{img.size[1]} px (logical {a.width}x{a.height}, scale {a.scale})")


ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
sub = ap.add_subparsers(dest="cmd", required=True)
p = sub.add_parser("stone"); p.set_defaults(fn=stone)
p.add_argument("out"); p.add_argument("width", type=int); p.add_argument("height", type=int)
p.add_argument("--alpha", type=float, default=0.88)
p = sub.add_parser("bar"); p.set_defaults(fn=bar)
p.add_argument("out"); p.add_argument("width", type=int); p.add_argument("height", type=int)
p.add_argument("--fill", default="4a2a20e6"); p.add_argument("--border", default="d0602aff")
p.add_argument("--border-width", type=float, default=1.5); p.add_argument("--tip", type=float, default=None)
p.add_argument("--scale", type=int, default=2); p.add_argument("--mid", default=None, help="also write the centre strip here")
p = sub.add_parser("rule"); p.set_defaults(fn=rule)
p.add_argument("out"); p.add_argument("width", type=int); p.add_argument("height", type=int)
p.add_argument("--color", default="7fb3aeff"); p.add_argument("--line-width", type=float, default=1)
p.add_argument("--star", action="store_true"); p.add_argument("--scale", type=int, default=2)
a = ap.parse_args()
a.fn(a)
