#!/usr/bin/env python3
"""
Crop transparent padding from logo.png, resize artwork to fill ~85% of a
1024x1024 canvas, center it, and save the result.
"""

from pathlib import Path
from PIL import Image

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
SOURCE = PROJECT_ROOT.parent / "logo.png"
OUTPUT = PROJECT_ROOT / "assets" / "images" / "logo.png"

CANVAS = 1024          # output size
FILL = 0.85            # artwork fills this fraction of the canvas
BG_COLOR = (0, 0, 0, 0)  # transparent background


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Source logo not found: {SOURCE}")

    img = Image.open(SOURCE).convert("RGBA")

    # ── 1. Auto-crop transparent padding ──────────────────────
    # getbbox returns the bounding box of non-zero (non-transparent) content
    bbox = img.getbbox()
    if bbox is None:
        raise ValueError("Image is fully transparent — nothing to crop")

    cropped = img.crop(bbox)
    cw, ch = cropped.size
    print(f"Original:  {img.size[0]}×{img.size[1]}")
    print(f"Cropped:   {cw}×{ch}")

    # ── 2. Scale artwork to fill 85 % of the canvas ──────────
    target_w = int(CANVAS * FILL)
    target_h = int(CANVAS * FILL)

    # fit inside the target box while keeping aspect ratio
    scale = min(target_w / cw, target_h / ch)
    new_w = int(cw * scale)
    new_h = int(ch * scale)

    resized = cropped.resize((new_w, new_h), Image.LANCZOS)
    print(f"Resized:   {new_w}×{new_h}  ({new_w / CANVAS * 100:.0f}% of canvas)")

    # ── 3. Center on transparent canvas ──────────────────────
    canvas = Image.new("RGBA", (CANVAS, CANVAS), BG_COLOR)
    offset_x = (CANVAS - new_w) // 2
    offset_y = (CANVAS - new_h) // 2
    canvas.paste(resized, (offset_x, offset_y), resized)

    # ── 4. Save ──────────────────────────────────────────────
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUTPUT, "PNG", optimize=True)
    print(f"Saved:      {OUTPUT}")
    print("Done!")


if __name__ == "__main__":
    main()
