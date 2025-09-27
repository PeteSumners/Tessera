extends CharacterDisplay
class_name TextDisplay

var cursor_x: int = 0
var cursor_y: int = 0

func _ready():
	display_default_text()

func write_text(text: String, fg: Color = Color.WHITE, bg: Color = Color.BLACK):
	for i in range(text.length()):
		var char = text[i]
		
		if char == "\n":
			# Newline: move to start of next row
			cursor_x = 0
			cursor_y += 1
			if cursor_y >= rows:
				scroll_up()
		else:
			# Regular character
			set_char(cursor_x, cursor_y, char, fg, bg)
			cursor_x += 1
			
			# Text wrapping: if we hit the edge, wrap to next line
			if cursor_x >= cols:
				cursor_x = 0
				cursor_y += 1
				if cursor_y >= rows:
					scroll_up()

func scroll_up():
	# Move all rows up by one, clear bottom row
	for y in range(rows - 1):
		char_grid[y] = char_grid[y + 1]
	
	# Clear the bottom row
	char_grid[rows - 1] = []
	for x in range(cols):
		char_grid[rows - 1].append({
			"char": 32,  # space
			"fg": Color.WHITE,
			"bg": Color.BLACK
		})
	
	cursor_y = rows - 1
	render_all()

func clear_screen():
	cursor_x = 0
	cursor_y = 0
	initialize_char_grid(cols, rows)
	render_all()

func display_default_text():
	clear_screen()
	
	# Title header
	write_text("=== GODOT TEXT DISPLAY DEMO ===\n\n", Color.CYAN)
	
	# Demo text with wrapping
	write_text("This is a demonstration of the TextDisplay class. ", Color.WHITE)
	write_text("It handles automatic text wrapping when lines exceed the column width of 80 characters. ", Color.LIGHT_GRAY)
	write_text("Watch how this long sentence wraps to the next line automatically!\n\n", Color.WHITE)
	
	# Colored text examples
	write_text("Colors: ", Color.WHITE)
	write_text("Red ", Color.RED)
	write_text("Green ", Color.GREEN)
	write_text("Blue ", Color.BLUE)
	write_text("Yellow ", Color.YELLOW)
	write_text("Magenta ", Color.MAGENTA)
	write_text("Cyan\n\n", Color.CYAN)
	
	# Lorem ipsum for more content
	write_text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n\n", Color.LIGHT_GRAY)
	
	# Technical info
	write_text("Display Info:\n", Color.YELLOW)
	write_text("- Resolution: " + str(cols) + "x" + str(rows) + " characters\n", Color.GREEN)
	write_text("- Pixel Size: " + str(pixel_width) + "x" + str(pixel_height) + " pixels\n", Color.GREEN)
	write_text("- Text wrapping: Enabled\n", Color.GREEN)
	write_text("- Scrolling: Automatic when full\n\n", Color.GREEN)
	
	# Code example
	write_text("Sample Code:\n", Color.CYAN)
	write_text("func example():\n", Color.WHITE)
	write_text("    write_text(\"Hello World!\", Color.GREEN)\n", Color.WHITE)
	write_text("    cursor_x = 0  # Move to start of line\n\n", Color.WHITE)
	
	# Fill up more space to demo scrolling
	for i in range(5):
		write_text("Line " + str(i + 1) + ": This is additional content to demonstrate scrolling behavior when the display fills up with text.\n", Color.LIGHT_BLUE)
	
	# Final message
	write_text("\n--- End of Demo ---", Color.MAGENTA)

# Utility functions for interactive use
func print_line(text: String, color: Color = Color.WHITE):
	write_text(text + "\n", color)

func set_cursor_position(x: int, y: int):
	cursor_x = clamp(x, 0, cols - 1)
	cursor_y = clamp(y, 0, rows - 1)

func get_cursor_position() -> Vector2i:
	return Vector2i(cursor_x, cursor_y)
