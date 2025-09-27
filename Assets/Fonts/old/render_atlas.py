from PIL import Image, ImageDraw, ImageFont
import json

FONT_PATH = "NotoSansMono-Regular.ttf"
FONT_SIZE = 32
COLUMNS = 16

# Define codepoints
ascii_start = 32
ascii_end = 127  # 32 to 126 inclusive

cyrillic_upper_start = 0x410  # А
cyrillic_upper_end = 0x42F + 1  # Я

cyrillic_lower_start = 0x430  # а
cyrillic_lower_end = 0x44F + 1  # я

special_chars = [0x401, 0x451]  # Ё, ё

codepoints = list(range(ascii_start, ascii_end)) + special_chars + \
             list(range(cyrillic_upper_start, cyrillic_upper_end)) + \
             list(range(cyrillic_lower_start, cyrillic_lower_end))

# Load font
font = ImageFont.truetype(FONT_PATH, FONT_SIZE)

# Create dummy draw for measuring glyph bounding boxes
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

# Find max vertical extents relative to baseline
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

GLYPH_COUNT = len(codepoints)
ROWS = (GLYPH_COUNT + COLUMNS - 1) // COLUMNS

atlas_width = COLUMNS * GLYPH_BOX_WIDTH
atlas_height = ROWS * GLYPH_BOX_HEIGHT

atlas_image = Image.new("L", (atlas_width, atlas_height), color=0)
draw = ImageDraw.Draw(atlas_image)

metadata = {}

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

print(f"Generated fixed-grid baseline-fixed atlas {atlas_image.size} with {GLYPH_COUNT} glyphs.")

# --------- Rendering function ---------

def render_text_from_atlas(text, atlas_image, metadata, glyph_box_width, glyph_box_height, columns):
    img_width = glyph_box_width * len(text)
    img_height = glyph_box_height

    out_img = Image.new("L", (img_width, img_height), color=0)

    for i, ch in enumerate(text):
        cp = str(ord(ch))
        if cp not in metadata:
            # Optionally draw a placeholder or space; here we skip
            continue
        
        row, col = metadata[cp]
        glyph_box = (col * glyph_box_width, row * glyph_box_height,
                     (col + 1) * glyph_box_width, (row + 1) * glyph_box_height)

        glyph = atlas_image.crop(glyph_box)
        out_img.paste(glyph, (i * glyph_box_width, 0))

    return out_img

# --------- Test render ---------

if __name__ == "__main__":
    test_strings = [
        "Hello, world!",
        "Привет, мир!",
        "Ёё and ASCII mix!",
        "Mixed: ABC АБВ xyz ёЁ"
    ]

    for idx, s in enumerate(test_strings):
        img = render_text_from_atlas(s, atlas_image, metadata, GLYPH_BOX_WIDTH, GLYPH_BOX_HEIGHT, COLUMNS)
        filename = f"rendered_text_{idx + 1}.png"
        img.save(filename)
        print(f"Saved rendered string {idx + 1} to {filename}")

