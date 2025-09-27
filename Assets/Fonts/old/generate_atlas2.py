# ============================
# font_atlas_generator.py
# ============================
#
# Generates:
# - font_atlas_fixed_grid_baseline_fixed.png
# - font_atlas_fixed_grid_baseline_fixed_metadata.json
# - font_atlas_fixed_grid_baseline_fixed_fontinfo.json
#
# Supports: ASCII + Cyrillic + Ёё
# ============================

from PIL import Image, ImageDraw, ImageFont
import json

# ========== CONFIG ==========

FONT_PATH = "NotoSansMono-Regular.ttf"
FONT_SIZE = 16
COLUMNS = 16

# ========== CODEPOINT RANGES ==========

ascii_start = 32
ascii_end = 127  # 32 to 126 inclusive

cyrillic_upper_start = 0x410  # А
cyrillic_upper_end = 0x42F + 1  # Я

cyrillic_lower_start = 0x430  # а
cyrillic_lower_end = 0x44F + 1  # я

special_chars = [0x401, 0x451]  # Ё, ё

codepoints = (
    list(range(ascii_start, ascii_end)) +
    special_chars +
    list(range(cyrillic_upper_start, cyrillic_upper_end)) +
    list(range(cyrillic_lower_start, cyrillic_lower_end))
)

# ========== LOAD FONT ==========

font = ImageFont.truetype(FONT_PATH, FONT_SIZE)

# ========== MEASURE GLYPH BOUNDING BOXES ==========

dummy_img = Image.new("L", (FONT_SIZE * 3, FONT_SIZE * 3), 0)
dummy_draw = ImageDraw.Draw(dummy_img)

max_width = 0
glyph_bboxes = {}

for cp in codepoints:
    char = chr(cp)
    bbox = dummy_draw.textbbox((0, 0), char, font=font)
    glyph_bboxes[cp] = bbox

    width = bbox[2] - bbox[0]
    if width > max_width:
        max_width = width

# ========== COMPUTE MAX VERTICAL EXTENTS ==========

max_above_baseline = 0
max_below_baseline = 0

for bbox in glyph_bboxes.values():
    top = bbox[1]    # usually negative or zero (above baseline)
    bottom = bbox[3] # usually positive or zero (below baseline)

    if -top > max_above_baseline:
        max_above_baseline = -top
    if bottom > max_below_baseline:
        max_below_baseline = bottom

GLYPH_BOX_WIDTH = max_width
GLYPH_BOX_HEIGHT = int(max_above_baseline + max_below_baseline)
baseline_offset = int(max_above_baseline)

# ========== CREATE ATLAS IMAGE ==========

GLYPH_COUNT = len(codepoints)
ROWS = (GLYPH_COUNT + COLUMNS - 1) // COLUMNS

atlas_width = COLUMNS * GLYPH_BOX_WIDTH
atlas_height = ROWS * GLYPH_BOX_HEIGHT

atlas_image = Image.new("L", (atlas_width, atlas_height), color=0)
draw = ImageDraw.Draw(atlas_image)

metadata = {}

# ========== RENDER GLYPHS ==========

for i, cp in enumerate(codepoints):
    row = i // COLUMNS
    col = i % COLUMNS

    cell_x = col * GLYPH_BOX_WIDTH
    cell_y = row * GLYPH_BOX_HEIGHT

    char = chr(cp)
    bbox = glyph_bboxes[cp]

    offset_x = -bbox[0]  # compensate left side bearing
    y = cell_y + baseline_offset

    draw.text((cell_x + offset_x, y), char, font=font, fill=255)

    metadata[str(cp)] = [row, col]

# ========== SAVE RESULTS ==========

atlas_image.save("font_atlas_fixed_grid_baseline_fixed.png")

with open("font_atlas_fixed_grid_baseline_fixed_metadata.json", "w", encoding="utf-8") as f:
    json.dump(metadata, f, ensure_ascii=False, indent=2)

# ========== SAVE FONT INFO FOR RENDERING SCRIPTS ==========

font_info = {
    "glyph_box_width": GLYPH_BOX_WIDTH,
    "glyph_box_height": GLYPH_BOX_HEIGHT,
    "columns": COLUMNS,
    "baseline_offset": baseline_offset,
    "font_size": FONT_SIZE
}

with open("font_atlas_fixed_grid_baseline_fixed_fontinfo.json", "w", encoding="utf-8") as f:
    json.dump(font_info, f, ensure_ascii=False, indent=2)

# ========== SUMMARY OUTPUT ==========

print("\n=====================")
print(f"Generated atlas: {atlas_image.size} px")
print(f"Glyph count: {GLYPH_COUNT}")
print(f"GLYPH_BOX_WIDTH  = {GLYPH_BOX_WIDTH}")
print(f"GLYPH_BOX_HEIGHT = {GLYPH_BOX_HEIGHT}")
print("=====================\n")
