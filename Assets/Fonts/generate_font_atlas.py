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
# Produces: SOLID WHITE glyphs (NO anti-aliasing)
# ============================
from PIL import Image, ImageDraw, ImageFont
import json

# ========== CONFIG ==========
FONT_PATH = "NotoSansMono-Regular.ttf"
TARGET_GLYPH_SIZE = 32  # Target size for glyphs (they'll be scaled to fit this)
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

# ========== LOAD FONT AT NATURAL SIZE FIRST ==========
base_font_size = 16
font = ImageFont.truetype(FONT_PATH, base_font_size)

# ========== MEASURE GLYPH BOUNDING BOXES ==========
dummy_img = Image.new("L", (base_font_size * 3, base_font_size * 3), 0)
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

# Natural proportions from the font
natural_width = max_width
natural_height = int(max_above_baseline + max_below_baseline)
natural_baseline_offset = int(max_above_baseline)

# Scale everything to target size (keeping proportions)
scale_factor = TARGET_GLYPH_SIZE / max(natural_width, natural_height)
FONT_SIZE = int(base_font_size * scale_factor)
GLYPH_BOX_WIDTH = int(natural_width * scale_factor)
GLYPH_BOX_HEIGHT = int(natural_height * scale_factor)
baseline_offset = int(natural_baseline_offset * scale_factor)

# Reload font at the scaled size
font = ImageFont.truetype(FONT_PATH, FONT_SIZE)

# ========== CREATE ATLAS IMAGE ==========
GLYPH_COUNT = len(codepoints)
ROWS = (GLYPH_COUNT + COLUMNS - 1) // COLUMNS

atlas_width = COLUMNS * GLYPH_BOX_WIDTH
atlas_height = ROWS * GLYPH_BOX_HEIGHT

# Create atlas directly at target size (no high-res temporary image)
atlas_image = Image.new("L", (atlas_width, atlas_height), color=0)
atlas_draw = ImageDraw.Draw(atlas_image)

metadata = {}

# ========== RENDER GLYPHS DIRECTLY AT TARGET SIZE ==========
for i, cp in enumerate(codepoints):
    row = i // COLUMNS
    col = i % COLUMNS
    
    cell_x = col * GLYPH_BOX_WIDTH
    cell_y = row * GLYPH_BOX_HEIGHT
    
    char = chr(cp)
    # Get bbox at target size
    bbox = atlas_draw.textbbox((0, 0), char, font=font)
    
    offset_x = -bbox[0]  # compensate left side bearing
    y = cell_y + baseline_offset
    
    atlas_draw.text((cell_x + offset_x, y), char, font=font, fill=255)
    metadata[str(cp)] = [row, col]

# ========== CONVERT TO RGBA WITH HARD THRESHOLD ==========
# Convert to RGBA for transparency support
atlas_rgba = Image.new("RGBA", (atlas_width, atlas_height), (0, 0, 0, 0))

# Hard threshold: convert grayscale to solid white or transparent (no anti-aliasing)
pixels = atlas_image.load()
rgba_pixels = atlas_rgba.load()

threshold = 1  # Very low threshold - any non-zero pixel becomes solid white

for y in range(atlas_height):
    for x in range(atlas_width):
        gray_value = pixels[x, y]
        if gray_value >= threshold:
            rgba_pixels[x, y] = (255, 255, 255, 255)  # Solid white
        else:
            rgba_pixels[x, y] = (0, 0, 0, 0)  # Transparent

# ========== SAVE RESULTS ==========
atlas_rgba.save("font_atlas_fixed_grid_baseline_fixed.png")

with open("font_atlas_fixed_grid_baseline_fixed_metadata.json", "w", encoding="utf-8") as f:
    json.dump(metadata, f, ensure_ascii=False, indent=2)

# ========== SAVE FONT INFO FOR RENDERING SCRIPTS ==========
font_info = {
    "glyph_box_width": GLYPH_BOX_WIDTH,
    "glyph_box_height": GLYPH_BOX_HEIGHT,
    "columns": COLUMNS,
    "baseline_offset": baseline_offset,
    "font_size": FONT_SIZE,
    "target_glyph_size": TARGET_GLYPH_SIZE,
    "scale_factor": scale_factor,
    "threshold": threshold,
    "format": "RGBA_solid_white_no_antialiasing"
}

with open("font_atlas_fixed_grid_baseline_fixed_fontinfo.json", "w", encoding="utf-8") as f:
    json.dump(font_info, f, ensure_ascii=False, indent=2)

# ========== SUMMARY OUTPUT ==========
print("\n=====================")
print(f"Generated atlas: {atlas_rgba.size} px")
print(f"Glyph count: {GLYPH_COUNT}")
print(f"TARGET_GLYPH_SIZE = {TARGET_GLYPH_SIZE}")
print(f"GLYPH_BOX_WIDTH  = {GLYPH_BOX_WIDTH}")
print(f"GLYPH_BOX_HEIGHT = {GLYPH_BOX_HEIGHT}")
print(f"Scale factor: {scale_factor:.2f}")
print(f"Font size: {FONT_SIZE}")
print(f"Format: RGBA with solid white glyphs (NO anti-aliasing)")
print("=====================\n")
