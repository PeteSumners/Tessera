extends PixelDisplay
class_name CharacterDisplay

var char_grid : Array = []  # 2D array of cells
var cols : int
var rows : int

func _init() -> void:
	# Determine glyph size
	var glyph_w = AtlasHelper.get_glyph_width()
	var glyph_h = AtlasHelper.get_glyph_height()
	# Desired terminal dimensions
	cols = 80
	rows = 25
	# Calculate pixel display size from desired rows/cols
	pixel_width = cols * glyph_w
	pixel_height = rows * glyph_h
	initialize_char_grid(cols, rows)
	super(pixel_width, pixel_height)

func _ready() -> void:
	demo_rainbow_characters()

func initialize_char_grid(cols: int, rows: int):
	char_grid.resize(rows)
	for y in range(rows):
		char_grid[y] = []
		for x in range(cols):
			char_grid[y].append({
				"char": 32,  # space
				"fg": Color(1,1,1,1),  # white foreground
				"bg": Color(0,0,0,1),  # black background
			})

func set_char(x: int, y: int, char: String, fg: Color=Color(1,1,1,1), bg: Color=Color(0,0,0,1)):
	if x < 0 or x >= cols or y < 0 or y >= rows:
		return
	
	var cp = char.unicode_at(0)
	char_grid[y][x]["char"] = cp
	char_grid[y][x]["fg"] = fg
	char_grid[y][x]["bg"] = bg
	
	draw_char(x, y)

func draw_char(x: int, y: int):
	var cell = char_grid[y][x]
	var cp = cell["char"]
	
	var glyph_w = AtlasHelper.font_info["glyph_box_width"]
	var glyph_h = AtlasHelper.font_info["glyph_box_height"]
	
	var dest_x = x * glyph_w
	var dest_y = y * glyph_h
	
	# Draw background first
	draw_rect(dest_x, dest_y, glyph_w, glyph_h, [cell["bg"].r, cell["bg"].g, cell["bg"].b, cell["bg"].a])
	
	# Draw glyph with foreground color
	if AtlasHelper.metadata.has(str(cp)):
		var glyph_img = AtlasHelper.get_glyph_image(char(cp))
		if glyph_img != null:
			# Apply foreground color to the glyph and blit
			blit_colored_glyph(glyph_img, Vector2i(dest_x, dest_y), cell["fg"])

func blit_colored_glyph(glyph_img: Image, dest_pos: Vector2i, fg_color: Color):
	"""
	Blits a glyph image to the display, applying the foreground color to non-transparent pixels.
	Assumes the glyph has transparent background and white/grayscale foreground.
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
				
			var pixel = glyph_img.get_pixel(x, y)
			
			# Skip transparent pixels (preserve background)
			if pixel.a < 0.01:
				continue
			
			# For non-transparent pixels, apply foreground color
			# The original pixel's brightness determines the intensity
			var brightness = (pixel.r + pixel.g + pixel.b) / 3.0
			var colored_pixel = Color(
				fg_color.r * brightness,
				fg_color.g * brightness, 
				fg_color.b * brightness,
				pixel.a
			)
			
			set_pixel(dest_x, dest_y, [colored_pixel.r, colored_pixel.g, colored_pixel.b, colored_pixel.a])

func render_all():
	clear_display()
	for y in range(rows):
		for x in range(cols):
			draw_char(x, y)
	needs_texture_update = true

# Convenience methods for common terminal operations
func set_text(x: int, y: int, text: String, fg: Color = Color(1,1,1,1), bg: Color = Color(0,0,0,1)):
	"""Set multiple characters in a row"""
	for i in range(text.length()):
		if x + i >= cols:
			break
		set_char(x + i, y, text[i], fg, bg)

func fill_rect_chars(x: int, y: int, width: int, height: int, char: String = " ", fg: Color = Color(1,1,1,1), bg: Color = Color(0,0,0,1)):
	"""Fill a rectangular area with a character and colors"""
	for row in range(height):
		if y + row >= rows:
			break
		for col in range(width):
			if x + col >= cols:
				break
			set_char(x + col, y + row, char, fg, bg)

func clear_screen(bg: Color = Color(0,0,0,1)):
	"""Clear the entire screen with a background color"""
	fill_rect_chars(0, 0, cols, rows, " ", Color(1,1,1,1), bg)


# Add this method to your CharacterDisplay class for a rainbow demo!
func demo_rainbow_characters():
	"""Displays a colorful rainbow character demonstration"""
	
	# Clear screen with dark background
	clear_screen(COLORS.BLACK)
	
	# Rainbow colors array
	var rainbow_colors = [
		Color(1.0, 0.0, 0.0, 1.0),  # Red
		Color(1.0, 0.5, 0.0, 1.0),  # Orange
		Color(1.0, 1.0, 0.0, 1.0),  # Yellow
		Color(0.0, 1.0, 0.0, 1.0),  # Green
		Color(0.0, 1.0, 1.0, 1.0),  # Cyan
		Color(0.0, 0.0, 1.0, 1.0),  # Blue
		Color(0.5, 0.0, 1.0, 1.0),  # Indigo
		Color(1.0, 0.0, 1.0, 1.0)   # Violet
	]
	
	# Title with cycling rainbow colors
	var title = "RAINBOW CHARACTERS DEMO!"
	var title_start_x = (cols - title.length()) / 2
	for i in range(title.length()):
		var color_index = i % rainbow_colors.size()
		set_char(title_start_x + i, 2, title[i], rainbow_colors[color_index], COLORS.BLACK)
	
	# Animated rainbow waves
	for row in range(5, 15):
		for col in range(cols):
			# Create wave pattern with different frequencies
			var wave1 = sin((col * 0.2) + (row * 0.5)) * 0.5 + 0.5
			var wave2 = cos((col * 0.15) + (row * 0.7)) * 0.5 + 0.5
			
			# Blend waves to create color
			var hue = (wave1 + wave2 * 0.3) * 6.0  # 6.0 for full spectrum
			var color = Color.from_hsv(fmod(hue, 1.0), 0.8, 0.9)
			
			# Use different characters for texture
			var chars = "░▒▓█●◆▲►"
			var char_index = int((wave1 + wave2) * chars.length()) % chars.length()
			
			set_char(col, row, chars[char_index], color, COLORS.BLACK)
	
	# Rainbow text examples
	var examples = [
		"Colorful ASCII Art!",
		"Each character can have",
		"its own foreground and",
		"background colors!"
	]
	
	for i in range(examples.size()):
		var text = examples[i]
		var y_pos = 17 + i
		var text_start_x = (cols - text.length()) / 2
		
		for j in range(text.length()):
			# Gradient from left to right
			var progress = float(j) / float(text.length() - 1)
			var hue = progress * 0.8  # Don't use full spectrum to avoid red-to-red
			var fg_color = Color.from_hsv(hue, 0.7, 1.0)
			var bg_color = Color.from_hsv(hue, 0.3, 0.2)  # Darker background
			
			set_char(text_start_x + j, y_pos, text[j], fg_color, bg_color)
	
	# Border with cycling colors
	for i in range(cols):
		var hue = float(i) / float(cols)
		var border_color = Color.from_hsv(hue, 1.0, 0.8)
		set_char(i, 0, "═", border_color, COLORS.BLACK)
		set_char(i, rows - 1, "═", border_color, COLORS.BLACK)
	
	for i in range(rows):
		var hue = float(i) / float(rows)
		var border_color = Color.from_hsv(hue, 1.0, 0.8)
		set_char(0, i, "║", border_color, COLORS.BLACK)
		set_char(cols - 1, i, "║", border_color, COLORS.BLACK)
	
	# Corner pieces
	set_char(0, 0, "╔", COLORS.WHITE, COLORS.BLACK)
	set_char(cols - 1, 0, "╗", COLORS.WHITE, COLORS.BLACK)
	set_char(0, rows - 1, "╚", COLORS.WHITE, COLORS.BLACK)
	set_char(cols - 1, rows - 1, "╝", COLORS.WHITE, COLORS.BLACK)
	
	# Force render update
	needs_texture_update = true

# Call this method to show the rainbow demo:
# var display = CharacterDisplay.new()
# display.demo_rainbow_characters()


# Color preset constants for convenience
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
	"WHITE": Color(1, 1, 1, 1)
}
