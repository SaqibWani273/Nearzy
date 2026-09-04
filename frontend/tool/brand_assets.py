#!/usr/bin/env python3
"""Regenerates the launcher-icon and splash source bitmaps under assets/images/.

The mark is a port of `_MarkPainter` in
lib/presentation/common/widgets/nearzy_logo.dart — the same 100x100 authoring
grid, the same tangent-blended pin, scalloped awning and subtracted doorway.
That file stays the source of truth; if the painter changes, change the
constants here to match and re-run:

    python3 tool/brand_assets.py            # rewrites assets/images/*
    fvm dart run flutter_launcher_icons     # then fan out to platform folders
    fvm dart run flutter_native_splash:create

The wordmark needs Plus Jakarta Sans ExtraBold, the face app_text_styles.dart
uses for brand type. google_fonts fetches it at runtime, so there is no copy in
the build to reuse — the variable font ships next to this script instead
(SIL Open Font License 1.1, from github.com/google/fonts).

Sizing is not arbitrary — every canvas below is pinned to a platform spec:

* Adaptive icons draw on a 108dp canvas but launchers only ever show the
  central 72dp of it, so a mark that should read at 62% of the *visible* icon
  has to be authored at 62% x 72/108 = 41.3% of the canvas. The old assets
  missed this twice over (a foreground that was itself mostly padding, plus a
  16% inset in launcher_icon.xml), which is why the pin came out tiny.
* flutter_native_splash treats every source as 4x, so 1152px = 288dp — the
  Android 12 splash-icon canvas. With an icon background colour the OS draws a
  240dp disc and content must stay inside a 160dp circle, i.e. 640px here.
  Handily, this mark's circumscribed circle diameter equals its bounding-box
  height, so `mark_height` doubles as the diameter to budget against.
* Older Android and iOS get no OS-drawn disc, so it is painted in here. Their
  disc is deliberately smaller than Android 12's 240dp — that figure is a
  design canvas the OS scales, whereas here the source size *is* the on-screen
  size, and a 240dp disc would swallow a 360dp-wide screen. Both keep the mark
  at DISC_FILL of the disc so the lockup reads identically everywhere.
"""

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont

# ── Palette — mirrors lib/theme/app_colors.dart ───────────────────────────
INK = (0x0F, 0x1A, 0x15)
PAPER = (0xF7, 0xF6, 0xF1)
LIME = (0xC9, 0xF2, 0x4E)

# ── Mark geometry, on the painter's 100x100 grid ──────────────────────────
CX, CY, R = 50.0, 40.0, 34.0
TIP_Y = 95.0
DOOR_HALF_W, DOOR_BOTTOM, DOOR_SPRING = 10.0, 70.0, 52.0
AWNING_TOP, AWNING_BOTTOM, SCALLOPS = 25.0, 40.0, 4

# How much of the lime disc the pin fills, on the splash. Android's ceiling for
# an icon with a background is 160/240 = 0.667; sitting just under it leaves
# room for rounding without looking inset.
DISC_FILL = 0.64

# Diameter of the baked disc on the Android 12 splash icon, on the 1152px
# canvas. Under the 768px circle AOSP masks to, and close enough to it that the
# badge keeps the size it had when the OS was painting the background.
A12_DISC = 720

BBOX = (CX - R, CY - R, CX + R, TIP_Y)
BBOX_W, BBOX_H = BBOX[2] - BBOX[0], BBOX[3] - BBOX[1]

SS = 4  # supersample factor; masks are drawn large and box-filtered down

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "images"
FONT = Path(__file__).resolve().parent / "PlusJakartaSans[wght].ttf"


def _pin(n=1440):
    """The silhouette: a circle tangent-blended into a point."""
    d = TIP_Y - CY
    alpha = math.acos(R / d)
    pts = [(CX, TIP_Y), (CX - R * math.sin(alpha), CY + R * math.cos(alpha))]
    start, sweep = math.pi / 2 + alpha, 2 * math.pi - 2 * alpha
    pts += [
        (CX + R * math.cos(start + sweep * i / n), CY + R * math.sin(start + sweep * i / n))
        for i in range(n + 1)
    ]
    return pts


def _door(n=240):
    """The arch, subtracted from the silhouette so the ground shows through."""
    pts = [(CX - DOOR_HALF_W, DOOR_BOTTOM)]
    pts += [
        (
            CX + DOOR_HALF_W * math.cos(math.pi + math.pi * i / n),
            DOOR_SPRING + DOOR_HALF_W * math.sin(math.pi + math.pi * i / n),
        )
        for i in range(n + 1)
    ]
    pts.append((CX + DOOR_HALF_W, DOOR_BOTTOM))
    return pts


def _awning(n=120):
    """The scalloped stripe, later intersected with the silhouette."""
    w = 2 * R / SCALLOPS
    pts = [(CX - R, AWNING_TOP)]
    for i in range(SCALLOPS):
        sx = CX - R + i * w
        p0 = (sx, AWNING_BOTTOM - 4)
        p1 = (sx + w / 2, AWNING_BOTTOM + 5)
        p2 = (sx + w, AWNING_BOTTOM - 4)
        pts.append(p0)
        for j in range(1, n + 1):
            t = j / n
            u = 1 - t
            pts.append(
                (
                    u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0],
                    u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1],
                )
            )
    pts.append((CX + R, AWNING_TOP))
    return pts


def _mask(size, points, ox, oy, scale):
    m = Image.new("L", (size * SS, size * SS), 0)
    ImageDraw.Draw(m).polygon(
        [((ox + x * scale) * SS, (oy + y * scale) * SS) for x, y in points], fill=255
    )
    return m


def mark(canvas, mark_height, body, accent):
    """A transparent `canvas`-square RGBA image holding the mark."""
    scale = mark_height / BBOX_H
    ox = canvas / 2 - (BBOX[0] + BBOX_W / 2) * scale
    oy = canvas / 2 - (BBOX[1] + BBOX_H / 2) * scale

    pin = _mask(canvas, _pin(), ox, oy, scale)
    body_mask = ImageChops.subtract(pin, _mask(canvas, _door(), ox, oy, scale))
    awning_mask = ImageChops.multiply(_mask(canvas, _awning(), ox, oy, scale), pin)

    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    for m, colour in ((body_mask, body), (awning_mask, accent)):
        layer = Image.new("RGBA", (canvas, canvas), colour + (255,))
        layer.putalpha(m.resize((canvas, canvas), Image.BOX))
        out = Image.alpha_composite(out, layer)
    return out


def disc(canvas, diameter, colour):
    """The lime ground, for the surfaces where no OS draws it for us."""
    m = Image.new("L", (canvas * SS, canvas * SS), 0)
    r = diameter * SS / 2
    c = canvas * SS / 2
    ImageDraw.Draw(m).ellipse([c - r, c - r, c + r, c + r], fill=255)
    out = Image.new("RGBA", (canvas, canvas), colour + (255,))
    out.putalpha(m.resize((canvas, canvas), Image.BOX))
    return out


# NearzyLogo sets the wordmark at `fontSize: size * 0.72` with
# `letterSpacing: -size * 0.028`, so its tracking relative to the font size is
# -0.028 / 0.72. Expressed in em here because this renderer has no `size`.
WORDMARK_TRACKING_EM = -0.028 / 0.72


def wordmark(px, colour, tracking_em=WORDMARK_TRACKING_EM, pad=8, pad_bottom=None):
    """'Nearzy' in Plus Jakarta Sans ExtraBold, tracked like NearzyLogo.

    `pad_bottom` is transparent space below the glyphs. The OS anchors the
    branding image to the bottom of the splash and gives no way to offset it,
    so padding inside the image is the only way to lift the wordmark off the
    screen edge.
    """
    up = 3  # render large, filter down — PIL has no subpixel text positioning
    font = ImageFont.truetype(str(FONT), px * up)
    font.set_variation_by_axes([800])
    text = "Nearzy"
    tracking = tracking_em * px * up

    advances = []
    for i, ch in enumerate(text):
        if i + 1 < len(text):
            pair = font.getlength(text[i : i + 2]) - font.getlength(text[i + 1])
        else:
            pair = font.getlength(ch)
        advances.append(pair + (tracking if i + 1 < len(text) else 0))

    w = int(sum(advances) + px * up)
    h = int(px * up * 2)
    big = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    x = px * up / 2
    for ch, adv in zip(text, advances):
        d.text((x, h / 2), ch, font=font, fill=colour + (255,), anchor="lm")
        x += adv

    big = big.resize((w // up, h // up), Image.BOX)
    box = big.split()[3].getbbox()
    cropped = big.crop(box)
    below = pad if pad_bottom is None else pad_bottom
    out = Image.new(
        "RGBA", (cropped.width + pad * 2, cropped.height + pad + below), (0, 0, 0, 0)
    )
    out.paste(cropped, (pad, pad))
    return out


def main():
    written = []

    def save(img, name):
        img.save(OUT / name)
        written.append((name, img.size))

    # Master icon — iOS, macOS, Windows and web all take this one full-bleed.
    # 62% of the canvas is the mark; iOS only rounds the corners, so what is
    # authored here is what ships.
    master = Image.new("RGBA", (1024, 1024), LIME + (255,))
    master = Image.alpha_composite(master, mark(1024, round(1024 * 0.62), INK, PAPER))
    save(master.convert("RGB").convert("RGBA"), "icon.png")

    # Android adaptive foreground — 41.3% of the 108dp canvas so it lands at
    # 62% of the 72dp the launcher actually shows. Paired with
    # adaptive_icon_foreground_inset: 0 in pubspec.yaml.
    save(mark(1024, round(1024 * 0.62 * 72 / 108), INK, PAPER), "icon_foreground.png")

    # Android 12+ splash icon. The disc is drawn here rather than left to
    # icon_background_color: that attribute is a *background*, and OEM shells
    # shape it with the launcher's own icon mask — on HyperOS with square icons
    # it came out a lime square. A disc inside the drawable is a circle
    # everywhere. 720px sits comfortably inside the 768px circle AOSP masks
    # the icon to when no background colour is set, so it never gets clipped.
    a12 = disc(1152, A12_DISC, LIME)
    a12 = Image.alpha_composite(a12, mark(1152, round(A12_DISC * DISC_FILL), INK, PAPER))
    save(a12, "splash_logo_android12.png")

    # Pre-Android-12 and iOS: disc baked in at 160dp on a 256dp canvas.
    legacy = disc(1024, 640, LIME)
    legacy = Image.alpha_composite(legacy, mark(1024, round(640 * DISC_FILL), INK, PAPER))
    save(legacy, "splash_logo.png")

    # The wordmark, sat at the bottom of the splash, with transparent space
    # below it so it does not sit on the screen edge.
    save(wordmark(96, PAPER, pad_bottom=64), "splash_branding.png")

    for name, size in written:
        print(f"  {name:34s} {size[0]}x{size[1]}")


if __name__ == "__main__":
    main()
