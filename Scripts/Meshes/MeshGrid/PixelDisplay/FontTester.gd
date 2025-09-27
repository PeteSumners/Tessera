extends PixelDisplay
class_name FontTester

const IMAGE_PATH = "res://Assets/Fonts/font_atlas_fixed_grid_baseline_fixed.png"
const METADATA_PATH = "res://Assets/Fonts/font_atlas_fixed_grid_baseline_fixed_metadata.json"
const FONTINFO_PATH = "res://Assets/Fonts/font_atlas_fixed_grid_baseline_fixed_fontinfo.json"

var metadata = {}    # Dictionary<int, Array>
var font_info = {}   # Dictionary

var atlas_image: Image = null

func _ready():
	# Load font metadata and info
	_load_font_data()

	# Load image atlas
	atlas_image = Image.new()
	var err = atlas_image.load(IMAGE_PATH)
	if err != OK:
		push_error("Failed to load image: %s" % IMAGE_PATH)
		return

	# Display the entire atlas as an initial test (optional)
	display_image(atlas_image)

	# Draw a line of 64 'A's side by side
	draw_line_of_As()
	
	# Draw test string
	draw_text_line("Hello Привет Ёё", 0, 20)


func _load_font_data():
	metadata = _load_json_as_int_keys(METADATA_PATH)
	font_info = _load_json(FONTINFO_PATH)

func _load_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open JSON file: %s" % path)
		return {}
	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_error("Failed to parse JSON file: %s" % path)
		return {}

	return json.get_data()

func _load_json_as_int_keys(path: String) -> Dictionary:
	var raw = _load_json(path)
	var converted = {}
	for k in raw.keys():
		converted[int(k)] = raw[k]
	return converted

func draw_line_of_As():
	var cell_w = font_info.get("glyph_box_width", 8)
	var cell_h = font_info.get("glyph_box_height", 8)

	for i in range(64):
		blit_glyph_at("A", i * (cell_w + 1), 0)

func blit_glyph_at(char: String, dest_x: int, dest_y: int):
	var cp = char.unicode_at(0)
	if not metadata.has(cp):
		push_error("Glyph '%s' not found in metadata" % char)
		return

	var row_col = metadata[cp]
	var row = row_col[0]
	var col = row_col[1]

	var cell_w = font_info["glyph_box_width"]
	var cell_h = font_info["glyph_box_height"]

	var src_rect = Rect2(col * cell_w, row * cell_h, cell_w, cell_h)

	blit_image_region(atlas_image, src_rect, Vector2i(dest_x, dest_y))

func draw_text_line(text: String, start_x: int, start_y: int):
	var cell_w = font_info.get("glyph_box_width", 8)
	var cell_h = font_info.get("glyph_box_height", 8)

	var x = start_x
	for i in text.length():
		var char = text[i]
		blit_glyph_at(char, x, start_y)
		x += cell_w # adjust spacing as needed
