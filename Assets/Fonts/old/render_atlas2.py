# ============================
# font_atlas_renderer.py
# ============================
#
# Renders a string using:
# - font_atlas_fixed_grid_baseline_fixed.png
# - font_atlas_fixed_grid_baseline_fixed_metadata.json
# - font_atlas_fixed_grid_baseline_fixed_fontinfo.json
#
# Outputs:
# - rendered_text.png
# ============================

from PIL import Image
import json

# ========== CONFIG ==========

FONT_ATLAS_PATH = "font_atlas_fixed_grid_baseline_fixed.png"
METADATA_PATH = "font_atlas_fixed_grid_baseline_fixed_metadata.json"
FONTINFO_PATH = "font_atlas_fixed_grid_baseline_fixed_fontinfo.json"

STRING_TO_RENDER = (
    "The quick brown fox jumps over the lazy dog. 1234567890\n"
    "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG. ~!@#$%^&*()_+\n"
    "Привет, мир! Это тестовая строка для проверки глифов.\n"
    "Съешь ещё этих мягких французских булок да выпей чаю.\n"
    "Ёлка ёжик ЁЁ ёё Ёж ёлка ёмкость.\n"
    "Mixed ASCII and Cyrillic: Hello Привет Ёё ABC АБВ xyz.\n"
    "The quick brown fox jumps over the lazy dog again!\n"
    "Тестирование всех доступных символов в атласе.\n"
    "1234567890 ~!@#$%^&*()_+ []{}|;':,.<>/?\n"
    "End of test string for maximum coverage.\n"
)


# ========== LOAD DATA ==========

# Load atlas image
atlas_image = Image.open(FONT_ATLAS_PATH).convert("L")

# Load metadata
with open(METADATA_PATH, "r", encoding="utf-8") as f:
    metadata = json.load(f)

# Load font info
with open(FONTINFO_PATH, "r", encoding="utf-8") as f:
    font_info = json.load(f)

GLYPH_BOX_WIDTH = font_info["glyph_box_width"]
GLYPH_BOX_HEIGHT = font_info["glyph_box_height"]
COLUMNS = font_info["columns"]

# ========== RENDER STRING ==========

lines = STRING_TO_RENDER.split("\n")
num_lines = len(lines)
max_line_length = max(len(line) for line in lines)

output_width = max_line_length * GLYPH_BOX_WIDTH
output_height = num_lines * GLYPH_BOX_HEIGHT

output_image = Image.new("L", (output_width, output_height), color=0)

for line_idx, line in enumerate(lines):
    for char_idx, char in enumerate(line):
        cp = ord(char)

        # Skip rendering missing codepoints
        if str(cp) not in metadata:
            continue

        row, col = metadata[str(cp)]

        # Compute position in atlas
        x1 = col * GLYPH_BOX_WIDTH
        y1 = row * GLYPH_BOX_HEIGHT
        x2 = x1 + GLYPH_BOX_WIDTH
        y2 = y1 + GLYPH_BOX_HEIGHT

        glyph = atlas_image.crop((x1, y1, x2, y2))

        # Paste glyph into output image
        dest_x = char_idx * GLYPH_BOX_WIDTH
        dest_y = line_idx * GLYPH_BOX_HEIGHT

        output_image.paste(glyph, (dest_x, dest_y))

# ========== SAVE OUTPUT ==========

output_image.save("rendered_text.png")

# ========== SUMMARY OUTPUT ==========

print("\n=====================")
print(f"Rendered text saved to 'rendered_text.png'")
print(f"Output size: {output_image.size} px")
print("=====================\n")
