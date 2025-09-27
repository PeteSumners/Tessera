extends CharacterDisplay
class_name TerminalDisplay

var cursor_x: int = 0
var cursor_y: int = 0

var cursor_visible: bool = true
var cursor_timer: float = 0.0
var cursor_flash_time: float = 0.5  # seconds per blink

func _ready() -> void:
	var test_string = "Hello, world!\nThis is a resized terminal.\nRows: %d, Cols: %d" % [rows, cols]
	write_string(test_string)

	render_all()
	set_char(cursor_x, cursor_y, '_')

func _process(delta: float) -> void:
	super(delta)
	if cursor_timer >= cursor_flash_time: update_cursor_display()
	else: cursor_timer += delta

func update_cursor_display():
	if cursor_visible:
		set_current_char('_')
	else:
		set_current_char(' ')
	cursor_visible = !cursor_visible
	cursor_timer = 0

func write_char(ch: String):
	if ch == "\n":
		cursor_visible = false
		update_cursor_display()
		cursor_x = 0
		cursor_y += 1
	else:
		set_current_char(ch)
		cursor_x += 1
		if cursor_x >= cols:
			cursor_x = 0
			cursor_y += 1
	if cursor_y >= rows: # TODO: scroll till you see the cursor again
		cursor_y = rows - 1

func set_current_char(char: String, fg: Color=Color(1,1,1,1), bg: Color=Color(0,0,0,1)):
	set_char(cursor_x, cursor_y, char, fg, bg)

func backspace():
	if cursor_x == 0 and cursor_y == 0:
		return
	
	set_char(cursor_x, cursor_y, " ")
	
	if cursor_x == 0:
		cursor_y -= 1
		cursor_x = cols - 1
	else:
		cursor_x -= 1

func write_string(text: String, start_x: int=cursor_x, start_y: int=cursor_y):
	cursor_x = start_x
	cursor_y = start_y
	
	for i in text.length():
		write_char(text[i])
