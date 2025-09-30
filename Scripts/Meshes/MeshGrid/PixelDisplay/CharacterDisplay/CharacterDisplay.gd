extends PixelDisplay
class_name CharacterDisplay

var char_grid : Array = []  # 2D array of cells
var cols : int
var rows : int

# Blend modes
enum BlendMode {
	ADDITIVE,
	SUBTRACTIVE
}

func _init() -> void:
	# Determine glyph size
	var glyph_w = AtlasHelper.get_glyph_width()
	var glyph_h = AtlasHelper.get_glyph_height()
	# Default terminal dimensions
	cols = 80
	rows = 25
	# Calculate pixel display size from desired rows/cols
	pixel_width = cols * glyph_w
	pixel_height = rows * glyph_h
	initialize_char_grid(cols, rows)
	super(pixel_width, pixel_height)

func _ready() -> void:
	demo_russian_chars()

func initialize_char_grid(cols: int, rows: int):
	char_grid.resize(rows)
	for y in range(rows):
		char_grid[y] = []
		for x in range(cols):
			char_grid[y].append({
				"char": 32,  # space
				"fg": COLORS.WHITE,
				"bg": COLORS.BLACK,
				"blend_mode": BlendMode.ADDITIVE
			})

func resize_character_display(new_cols: int, new_rows: int):
	"""Resize the character display to new dimensions"""
	cols = new_cols
	rows = new_rows
	
	var glyph_w = AtlasHelper.get_glyph_width()
	var glyph_h = AtlasHelper.get_glyph_height()
	var new_pixel_width = cols * glyph_w
	var new_pixel_height = rows * glyph_h
	
	# Use the parent's resize method to update pixel dimensions
	resize_pixel_display(new_pixel_width, new_pixel_height)
	
	# Reinitialize character grid
	initialize_char_grid(cols, rows)

func set_char(x: int, y: int, char: String, fg: Color=COLORS.WHITE, bg: Color=COLORS.BLACK, blend_mode: BlendMode = BlendMode.ADDITIVE):
	if x < 0 or x >= cols or y < 0 or y >= rows:
		return
	
	var cp = char.unicode_at(0)
	char_grid[y][x]["char"] = cp
	char_grid[y][x]["fg"] = fg
	char_grid[y][x]["bg"] = bg
	char_grid[y][x]["blend_mode"] = blend_mode
	
	draw_char(x, y)

func draw_char(x: int, y: int):
	var cell = char_grid[y][x]
	var cp = cell["char"]
	
	var glyph_w = AtlasHelper.font_info["glyph_box_width"]
	var glyph_h = AtlasHelper.font_info["glyph_box_height"]
	
	var dest_x = x * glyph_w
	var dest_y = y * glyph_h
	
	# Always overwrite the cell with the new background
	draw_rect(dest_x, dest_y, glyph_w, glyph_h, [cell["bg"].r, cell["bg"].g, cell["bg"].b, cell["bg"].a])

	# Draw glyph with specified blend mode
	if AtlasHelper.metadata.has(str(cp)):
		var glyph_img = AtlasHelper.get_glyph_image(char(cp))
		if glyph_img != null:
			blit_glyph_with_mode(glyph_img, Vector2i(dest_x, dest_y), cell["fg"], cell["blend_mode"])

func blit_glyph_with_mode(glyph_img: Image, dest_pos: Vector2i, fg_color: Color, blend_mode: BlendMode):
	"""
	Blits a glyph image using the specified blend mode.
	ADDITIVE: bg.rgb += fg.rgb * fg.a, bg.a += fg.a
	SUBTRACTIVE: bg.rgb -= fg.rgb * fg.a, bg.a -= fg.a
	"""
	var glyph_w = glyph_img.get_width()
	var glyph_h = glyph_img.get_height()
	
	for y in range(glyph_h):
		var dest_y = dest_pos.y + y
		if dest_y < 0 or dest_y >= pixel_height:
			continue
			
		for x in range(glyph_w):
			var dest_x = dest_pos.x + x
			if dest_x < 0 or dest_x >= pixel_width:
				continue
				
			var glyph_pixel = glyph_img.get_pixel(x, y)
			
			# Skip completely transparent pixels
			if glyph_pixel.a == 0:
				continue
			
			var fg_alpha = fg_color.a * glyph_pixel.a
			var current_color = Color(get_pixel(dest_x, dest_y)[0], get_pixel(dest_x, dest_y)[1], get_pixel(dest_x, dest_y)[2], get_pixel(dest_x, dest_y)[3])
			var final_color = current_color
			
			match blend_mode:
				BlendMode.ADDITIVE:
					final_color.r += fg_color.r * fg_alpha
					final_color.g += fg_color.g * fg_alpha
					final_color.b += fg_color.b * fg_alpha
					final_color.a += fg_alpha
				BlendMode.SUBTRACTIVE:
					final_color.r -= fg_color.r * fg_alpha
					final_color.g -= fg_color.g * fg_alpha
					final_color.b -= fg_color.b * fg_alpha
					final_color.a -= fg_alpha
			
			final_color = final_color.clamp()
			set_pixel(dest_x, dest_y, [final_color.r, final_color.g, final_color.b, final_color.a])

func render_all():
	clear_display()
	for y in range(rows):
		for x in range(cols):
			draw_char(x, y)
	needs_texture_update = true

# Convenience methods for common terminal operations
func set_text(x: int, y: int, text: String, fg: Color = COLORS.WHITE, bg: Color = COLORS.BLACK, blend_mode: BlendMode = BlendMode.ADDITIVE):
	"""Set multiple characters in a row"""
	for i in range(text.length()):
		if x + i >= cols:
			break
		set_char(x + i, y, text[i], fg, bg, blend_mode)

func fill_rect_chars(x: int, y: int, width: int, height: int, char: String = " ", fg: Color = COLORS.WHITE, bg: Color = COLORS.BLACK, blend_mode: BlendMode = BlendMode.ADDITIVE):
	"""Fill a rectangular area with a character and colors"""
	for row in range(height):
		if y + row >= rows:
			break
		for col in range(width):
			if x + col >= cols:
				break
			set_char(x + col, y + row, char, fg, bg, blend_mode)

func clear_screen(bg: Color = COLORS.BLACK):
	"""Clear the entire screen with a background color"""
	fill_rect_chars(0, 0, cols, rows, " ", COLORS.WHITE, bg)

# Helper function to create transparent versions of colors
func make_transparent(color: Color, alpha: float) -> Color:
	"""Create a transparent version of a color with specified alpha"""
	return Color(color.r, color.g, color.b, alpha)

# Enhanced color preset constants with transparency helpers
const COLORS = {
	"BLACK": Color(0, 0, 0, 1),
	"DARK_RED": Color(0.5, 0, 0, 1),
	"DARK_GREEN": Color(0, 0.5, 0, 1),
	"DARK_YELLOW": Color(0.5, 0.5, 0, 1),
	"DARK_BLUE": Color(0, 0, 0.5, 1),
	"DARK_MAGENTA": Color(0.5, 0, 0.5, 1),
	"DARK_CYAN": Color(0, 0.5, 0.5, 1),
	"LIGHT_GRAY": Color(0.75, 0.75, 0.75, 1),
	"DARK_GRAY": Color(0.5, 0.5, 0.5, 1),
	"RED": Color(1, 0, 0, 1),
	"GREEN": Color(0, 1, 0, 1),
	"YELLOW": Color(1, 1, 0, 1),
	"BLUE": Color(0, 0, 1, 1),
	"MAGENTA": Color(1, 0, 1, 1),
	"CYAN": Color(0, 1, 1, 1),
	"ORANGE": Color(1, .5, 0, 1),
	"WHITE": Color(1, 1, 1, 1),
	"TRANSLUCENT_RED": Color(1, 0, 0, 0.5),
	"TRANSLUCENT_GREEN": Color(0, 1, 0, 0.5),
	"TRANSLUCENT_BLUE": Color(0, 0, 1, 0.5),
	"TRANSLUCENT_YELLOW": Color(1, 1, 0, 0.5),
	"TRANSLUCENT_CYAN": Color(0, 1, 1, 0.5),
	"TRANSLUCENT_MAGENTA": Color(1, 0, 1, 0.5),
	"TRANSLUCENT_ORANGE": Color(1, .5, 0, 1),
	"TRANSLUCENT_WHITE": Color(1, 1, 1, 0.5),
	"TRANSLUCENT_BLACK": Color(0, 0, 0, 0.5),
	"TRANSPARENT": Color(0, 0, 0, 0),
}

func demo_blend_modes():
	"""Simple demo: black background, white foreground, additive vs subtractive"""
	clear_screen(COLORS.BLACK)

	var text_add = "ADDITIVE"
	var text_sub = "SUBTRACTIVE"

	# Draw additive text in the top half
	var fg = COLORS.WHITE
	for i in range(text_add.length()):
		set_char(2 + i, 2, text_add[i], fg, COLORS.BLACK, BlendMode.ADDITIVE)

	# Draw subtractive text in the bottom half
	for i in range(text_sub.length()):
		set_char(2 + i, 5, text_sub[i], fg, COLORS.BLACK, BlendMode.SUBTRACTIVE)

	render_all()

func demo_rainbow():
	clear_screen(COLORS.BLACK)
	
	var blend_modes = [BlendMode.ADDITIVE, BlendMode.SUBTRACTIVE]
	
	var x = 0
	var y = 0
	
	for bg in COLORS.values():
		for fg in COLORS.values():
			for mode in blend_modes:
				if x >= cols:
					x = 0
					y += 1
				if y >= rows:
					break
				set_char(x, y, "A", fg, bg, mode)
				x += 1
	
	render_all()

func demo_russian_chars():
	clear_screen(COLORS.BLACK)

	# Basic Russian uppercase letters А to Я
	var russian_chars = [
		"А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й",
		"К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф",
		"Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я"
	]

	var fg_colors = [
		COLORS.RED, COLORS.GREEN, COLORS.BLUE, COLORS.YELLOW,
		COLORS.CYAN, COLORS.MAGENTA, COLORS.WHITE
	]

	var x = 0
	var y = 0
	for char in russian_chars:
		var fg = fg_colors[randi() % fg_colors.size()]
		set_char(x, y, char, fg, COLORS.BLACK, BlendMode.ADDITIVE)
		x += 1
		if x >= cols:
			x = 0
			y += 1
			if y >= rows:
				break

	render_all()
