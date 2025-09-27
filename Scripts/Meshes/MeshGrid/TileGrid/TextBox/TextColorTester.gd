extends ShaderTextBox
class_name TextColorTester

func _init():
	super()
	grid_x_len = 12  # Make it wide enough for our color words
	grid_y_len = 9   # One line per color

func _ready():
	super()
	display_color_words()

func display_color_words():
	# Each entry is [word, enum color value]
	var color_words = [
		["BLACK", MeshTextColor.BLACK],
		["BLUE", MeshTextColor.BLUE],
		["GREEN", MeshTextColor.GREEN],
		["CYAN", MeshTextColor.CYAN],
		["RED", MeshTextColor.RED],
		["MAGENTA", MeshTextColor.MAGENTA],
		["YELLOW", MeshTextColor.YELLOW],
		["WHITE", MeshTextColor.WHITE],
		["GRAY", MeshTextColor.GRAY]
	]
	
	var full_text = ""
	var current_pos = 0
	
	for entry in color_words:
		var word = entry[0]
		var color = entry[1]
		
		# Add word to the text
		full_text += word + "\n"
		
		# Color the word
		for i in range(len(word)):
			set_ascii_char_color(current_pos + i, color)
			
		current_pos += len(word) + 1  # +1 for newline
	
	set_string(full_text)
