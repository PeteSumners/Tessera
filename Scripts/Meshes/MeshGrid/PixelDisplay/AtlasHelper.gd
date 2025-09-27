extends Node

# =======================================
# AtlasHelper.gd (STATIC singleton)
# =======================================
const ATLAS_PATH = "res://Assets/Fonts/font_atlas_fixed_grid_baseline_fixed.png"
const METADATA_PATH = "res://Assets/Fonts/font_atlas_fixed_grid_baseline_fixed_metadata.json"
const FONTINFO_PATH = "res://Assets/Fonts/font_atlas_fixed_grid_baseline_fixed_fontinfo.json"

static var atlas_image : Image = null
static var metadata : Dictionary = {}
static var font_info : Dictionary = {}

func _init() -> void:
	if atlas_image != null:
		# Already initialized
		return

	# === Load atlas image ===
	atlas_image = Image.new()
	var err = atlas_image.load(ATLAS_PATH)
	if err != OK:
		push_error("Failed to load atlas image from %s" % ATLAS_PATH)
		atlas_image = null
		return
	
	# === Load metadata JSON ===
	var meta_file = FileAccess.open(METADATA_PATH, FileAccess.READ)
	if meta_file:
		metadata = JSON.parse_string(meta_file.get_as_text())
	else:
		push_error("Failed to load metadata JSON")
	
	# === Load font info JSON ===
	var info_file = FileAccess.open(FONTINFO_PATH, FileAccess.READ)
	if info_file:
		font_info = JSON.parse_string(info_file.get_as_text())
	else:
		push_error("Failed to load font info JSON")

static func get_glyph_width() -> int:
	return font_info.get("glyph_box_width", 8)  # Default fallback

static func get_glyph_height() -> int:
	return font_info.get("glyph_box_height", 16)  # Default fallback


static func get_glyph_image(char : String) -> Image:
	if atlas_image == null or char.is_empty():
		return null
	
	var cp = char.unicode_at(0)

	if not metadata.has(str(cp)):
		push_warning("Missing glyph for character: %s (codepoint %d)" % [char, cp])
		return null
	
	var glyph_w = font_info["glyph_box_width"]
	var glyph_h = font_info["glyph_box_height"]

	var row_col = metadata[str(cp)]
	var atlas_row = row_col[0]
	var atlas_col = row_col[1]

	var x1 = atlas_col * glyph_w
	var y1 = atlas_row * glyph_h

	return atlas_image.get_region(Rect2i(x1, y1, glyph_w, glyph_h))
