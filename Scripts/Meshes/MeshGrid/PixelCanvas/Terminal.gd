extends AnimatedTextDisplay
class_name Terminal

# Cursor state
var cursor_x: int = 0
var cursor_y: int = 0
var cursor_visible: bool = true
var cursor_blink_time: float = 0.0
var cursor_blink_rate: float = 0.5
var word_wrap_enabled: bool = false

# Character grid for editing
var char_grid: Array = []

func _init(columns: int = 80, rows: int = 25):
	super(columns, rows)
	initialize_grid()

func initialize_grid():
	char_grid.resize(visible_rows)
	for y in range(visible_rows):
		char_grid[y] = []
		for x in range(cols):
			char_grid[y].append({
				"char": " ",
				"fg": Color.WHITE,
				"bg": Color.BLACK
			})

func write_string(text: String, fg: Color = Color.WHITE, bg: Color = Color.BLACK):
	if word_wrap_enabled:
		# Word wrap the entire string first
		var wrapped_lines = TextUtils.word_wrap(text, cols)
		for i in range(wrapped_lines.size()):
			var line = wrapped_lines[i]
			for c in line:
				write_char(c, fg, bg)
			# Add newline except for last line
			if i < wrapped_lines.size() - 1:
				newline()
	else:
		# Original behavior - character by character
		for i in range(text.length()):
			write_char(text[i], fg, bg)

func set_char(x: int, y: int, char: String, fg: Color = Color.WHITE, bg: Color = Color.BLACK):
	if x < 0 or x >= cols or y < 0 or y >= char_grid.size():
		return
	
	char_grid[y][x] = {
		"char": char,
		"fg": fg,
		"bg": bg
	}
	
	render_char_to_text_layer(x, y)

func render_char_to_text_layer(x: int, y: int):
	var cell = char_grid[y][x]
	var glyph_x = x * glyph_width
	var glyph_y = y * glyph_height
	
	# Draw background
	for py in range(glyph_height):
		for px in range(glyph_width):
			text_layer.set_pixel(glyph_x + px, glyph_y + py, cell["bg"])
	
	# Draw glyph
	var glyph = AtlasHelper.get_glyph_image(cell["char"])
	if glyph:
		blit_colored_glyph(text_layer, glyph, glyph_x, glyph_y, cell["fg"])
	
	text_texture.update(text_layer)

func write_char(char: String, fg: Color = Color.WHITE, bg: Color = Color.BLACK):
	if char == "\n":
		newline()
		return
	
	set_char(cursor_x, cursor_y, char, fg, bg)
	cursor_x += 1
	
	if cursor_x >= cols:
		newline()

func backspace():
	if cursor_x == 0 and cursor_y == 0:
		return
	
	if cursor_x == 0:
		cursor_y -= 1
		cursor_x = cols - 1
	else:
		cursor_x -= 1
	
	set_char(cursor_x, cursor_y, " ")

func newline():
	cursor_x = 0
	cursor_y += 1
	
	if cursor_y >= visible_rows:
		scroll_up()
		cursor_y = visible_rows - 1

func scroll_up():
	# Move all rows up by one
	for y in range(visible_rows - 1):
		char_grid[y] = char_grid[y + 1]
	
	# Clear bottom row
	char_grid[visible_rows - 1] = []
	for x in range(cols):
		char_grid[visible_rows - 1].append({
			"char": " ",
			"fg": Color.WHITE,
			"bg": Color.BLACK
		})
	
	# Re-render entire text layer
	render_full_grid()

func render_full_grid():
	text_layer.fill(Color.BLACK)
	
	for y in range(visible_rows):
		for x in range(cols):
			var cell = char_grid[y][x]
			var glyph_x = x * glyph_width
			var glyph_y = y * glyph_height
			
			# Background
			for py in range(glyph_height):
				for px in range(glyph_width):
					text_layer.set_pixel(glyph_x + px, glyph_y + py, cell["bg"])
			
			# Glyph
			var glyph = AtlasHelper.get_glyph_image(cell["char"])
			if glyph:
				blit_colored_glyph(text_layer, glyph, glyph_x, glyph_y, cell["fg"])
	
	text_texture.update(text_layer)

func clear_screen():
	cursor_x = 0
	cursor_y = 0
	initialize_grid()
	render_full_grid()

func update_animation_layer():
	# Clear animation layer
	animation_layer.fill(Color(0, 0, 0, 0))
	
	# Update cursor blink
	cursor_blink_time += get_process_delta_time()
	if cursor_blink_time >= cursor_blink_rate:
		cursor_visible = !cursor_visible
		cursor_blink_time = 0.0
	
	# Draw cursor if visible
	if cursor_visible:
		draw_cursor()

func draw_cursor():
	var cursor_glyph_x = cursor_x * glyph_width
	var cursor_glyph_y = cursor_y * glyph_height
	
	# Draw cursor as underscore
	var cursor_img = AtlasHelper.get_glyph_image("_")
	if cursor_img:
		blit_colored_glyph(animation_layer, cursor_img, cursor_glyph_x, cursor_glyph_y, Color.WHITE)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			newline()
		elif event.keycode == KEY_BACKSPACE:
			backspace()
		elif event.keycode == KEY_TAB:
			write_char("\t")
		elif event.unicode > 0:
			var char = char(event.unicode)
			if char >= " " and char <= "~":  # Printable ASCII
				write_char(char)
