from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path("/Users/skeptict/Documents/GitHub/TanquePatterns/TanquePatterns")
ICONSET = ROOT / "TanquePatterns" / "Assets.xcassets" / "AppIcon.appiconset"

BG = "#101114"
GOLD = "#d7ad5c"
GOLD_DIM = "#6f5430"
IVORY = "#ece7de"


def polar(center: tuple[float, float], radius: float, angle_deg: float) -> tuple[float, float]:
    angle = math.radians(angle_deg - 90)
    return (
        center[0] + math.cos(angle) * radius,
        center[1] + math.sin(angle) * radius,
    )


def draw_rosette(draw: ImageDraw.ImageDraw, size: int) -> None:
    center = (size / 2, size / 2)
    outer = size * 0.33
    inner = size * 0.20
    spoke_inner = size * 0.08
    stroke = max(4, round(size * 0.015))
    thin = max(2, round(size * 0.006))

    ring_r = size * 0.37
    for i in range(36):
        if i % 2 == 0:
            a0 = i * 10
            a1 = a0 + 5
            p0 = polar(center, ring_r, a0)
            p1 = polar(center, ring_r, a1)
            draw.line([p0, p1], fill=GOLD_DIM, width=thin)

    for angle in (0, 45, 90, 135):
        p0 = polar(center, size * 0.46, angle)
        p1 = polar(center, size * 0.46, angle + 180)
        draw.line([p0, p1], fill=GOLD_DIM, width=thin)

    outer_pts = [polar(center, outer, i * 30) for i in range(12)]
    inner_pts = [polar(center, inner, i * 30 + 15) for i in range(12)]

    for i in range(12):
        a = outer_pts[i]
        b = inner_pts[i]
        c = outer_pts[(i + 1) % 12]
        draw.line([a, b], fill=GOLD, width=stroke)
        draw.line([b, c], fill=GOLD, width=stroke)

    for i in range(12):
        a = outer_pts[i]
        b = inner_pts[(i + 11) % 12]
        c = inner_pts[i]
        draw.line([a, c], fill=GOLD, width=thin)
        draw.line([b, c], fill=GOLD, width=thin)

    for i in range(12):
        a = polar(center, spoke_inner, i * 30 + 15)
        b = outer_pts[i]
        draw.line([a, b], fill=GOLD, width=stroke)

    dot = size * 0.012
    draw.ellipse(
        (center[0] - dot, center[1] - dot, center[0] + dot, center[1] + dot),
        fill=GOLD,
    )

    pad = size * 0.08
    arm = size * 0.09
    offsets = [
        ((pad, pad), 0),
        ((size - pad, pad), 90),
        ((size - pad, size - pad), 180),
        ((pad, size - pad), 270),
    ]
    for (x, y), rot in offsets:
        pts = [
            polar((x, y), arm, rot - 25),
            (x, y),
            polar((x, y), arm, rot + 25),
        ]
        draw.line(pts, fill=IVORY, width=thin)


def build_master(size: int = 1024) -> Image.Image:
    image = Image.new("RGBA", (size, size), BG)
    draw = ImageDraw.Draw(image)
    draw_rosette(draw, size)
    return image


def main() -> None:
    ICONSET.mkdir(parents=True, exist_ok=True)
    master = build_master(1024)

    outputs = {
        "icon_16.png": 16,
        "icon_32.png": 32,
        "icon_64.png": 64,
        "icon_128.png": 128,
        "icon_256.png": 256,
        "icon_512.png": 512,
        "icon_1024.png": 1024,
    }

    for filename, size in outputs.items():
        image = master.resize((size, size), Image.Resampling.LANCZOS)
        image.save(ICONSET / filename)


if __name__ == "__main__":
    main()
