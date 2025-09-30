extends CharacterDisplay
class_name TextDisplay

# --- Text Buffer ---
var buffer : Array = []          # Array of lines (each line is a String)
var cursor_row : int = 0
var cursor_col : int = 0

# --- Viewport / Scrolling ---
var scroll_offset : int = 0      # Topmost visible line
var wrap_enabled : bool = true   # Wrap long lines at column width

# --- Cursor Rendering ---
var cursor_fg : Color = COLORS.BLACK
var cursor_bg : Color = COLORS.WHITE
var cursor_visible : bool = true

# --- Initialization ---
func _init(cols: int = 80, rows: int = 25) -> void:
	# Call parent constructor
	super._init()
	self.cols = cols
	self.rows = rows

	# Initialize buffer with empty lines
	for i in range(rows):
		buffer.append("")

func _ready() -> void:
	demo()

func clear_buffer():
	buffer.clear()
	for i in range(rows):
		buffer.append("")
	cursor_row = 0
	cursor_col = 0
	scroll_offset = 0
	render_all()

# --- Cursor Management ---
func move_cursor(dx: int, dy: int):
	cursor_row = clamp(cursor_row + dy, 0, buffer.size() - 1)
	cursor_col = clamp(cursor_col + dx, 0, buffer[cursor_row].length())
	ensure_cursor_visible()

func ensure_cursor_visible():
	if cursor_row < scroll_offset:
		scroll_offset = cursor_row
	elif cursor_row >= scroll_offset + rows:
		scroll_offset = cursor_row - rows + 1

func insert_char(char: String, do_render: bool = true):
	var line = buffer[cursor_row]
	line = line.substr(0, cursor_col) + char + line.substr(cursor_col)
	buffer[cursor_row] = line
	cursor_col += 1
	if do_render:
		render_all()

func delete_char(do_render: bool = true):
	var line = buffer[cursor_row]
	if cursor_col < line.length():
		line = line.substr(0, cursor_col) + line.substr(cursor_col + 1)
		buffer[cursor_row] = line
	elif cursor_row < buffer.size() - 1:
		buffer[cursor_row] += buffer[cursor_row + 1]
		buffer.remove_at(cursor_row + 1)
	if do_render:
		render_all()

func backspace(do_render: bool = true):
	if cursor_col > 0:
		var line = buffer[cursor_row]
		line = line.substr(0, cursor_col - 1) + line.substr(cursor_col)
		buffer[cursor_row] = line
		cursor_col -= 1
	elif cursor_row > 0:
		var prev_line_len = buffer[cursor_row - 1].length()
		buffer[cursor_row - 1] += buffer[cursor_row]
		buffer.remove_at(cursor_row)
		cursor_row -= 1
		cursor_col = prev_line_len
	if do_render:
		render_all()

func insert_newline():
	var line = buffer[cursor_row]
	var before = line.substr(0, cursor_col)
	var after = line.substr(cursor_col)
	buffer[cursor_row] = before
	buffer.insert(cursor_row + 1, after)
	cursor_row += 1
	cursor_col = 0
	render_all()

func render_all():
	clear_screen(COLORS.BLACK)
	
	var y_offset = 0
	var wrapped_lines = []  # Keep track of all visual rows for cursor mapping
	
	# Build wrapped lines
	for line in buffer:
		var start = 0
		while start < line.length():
			var chunk = line.substr(start, cols)
			wrapped_lines.append(chunk)
			start += cols
		if line.length() == 0:
			wrapped_lines.append("")  # Preserve empty lines

	# Render only visible portion based on scroll_offset
	for y in range(rows):
		var idx = scroll_offset + y
		if idx >= wrapped_lines.size():
			break
		set_text(0, y, wrapped_lines[idx], COLORS.WHITE, COLORS.BLACK, BlendMode.ADDITIVE)

	# Draw cursor if visible
	if cursor_visible:
		var visual_cursor_y = 0
		var visual_cursor_x = cursor_col
		var row_count = 0
		for i in range(cursor_row):
			row_count += int(ceil(float(buffer[i].length()) / cols))
		visual_cursor_y = row_count + cursor_col / cols
		visual_cursor_x = cursor_col % cols

		var cy = visual_cursor_y - scroll_offset
		if cy >= 0 and cy < rows:
			var cur_line = buffer[cursor_row]
			var char_at_cursor = cur_line[cursor_col] if cursor_col < cur_line.length() else " "
			set_char(visual_cursor_x, cy, char_at_cursor, cursor_bg, cursor_fg, BlendMode.ADDITIVE)

	needs_texture_update = true


# --- Convenience ---
func set_text_at_cursor(text: String):
	for c in text:
		insert_char(c)

func demo():
	clear_buffer()

	# --- Insert multiple lines efficiently ---
	var demo_text = [
		"1Hello, TextDisplay Demo!",
		"2This is a multiline text buffer.",
		"3You can move the cursor, insert characters,",
		"4delete characters, and handle newlines.",
		"5Scrolling works too if content exceeds view.",
		"6Try wrapping long lines like this one that is super long and will be clipped _if wrap is enabled.",
		"7End of demo."
	]

	for line in demo_text:
		buffer[cursor_row] = line
		cursor_row += 1
		buffer.insert(cursor_row, "")  # Add empty line for next
	cursor_row = 0
	cursor_col = 0

	# --- Demonstrate cursor editing ---
	move_cursor(10, 2)  # Move to row 2, col 10
	insert_char('-', false)
	insert_char('-', false)
	insert_char('-', false)

	move_cursor(-5, -1)  # Move back to row 1, col 5
	delete_char(false)

	move_cursor(0, 2)  # Move to row 3, col 5
	backspace(false)

	# --- Scroll demonstration ---
	scroll_offset = 0
	render_all()
