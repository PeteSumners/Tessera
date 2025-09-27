# a text box you can type in!
extends WordBox
class_name TypeBox

var base_color = MeshTextColor.WHITE # color to return to when done typing
var typing_color = MeshTextColor.YELLOW # color to display while typing
var input_chars = [] # the chars currently being typed
var prefix = "> " # placed before input strings

# get the maximum allowed number of input characters
func max_input_chars():
	return num_chars() - len(prefix)

# changes base color, and triggers a color update if necessary
func update_base_color(new_base_color):
	base_color = new_base_color
	if not has_input: update_color(base_color)

func _init():
	super()
	display_input_chars() # get the base text printed
	#return_input() # triggers a reliable update

func _input(event):
	if not is_local: return # don't do anything if the ChatBox isn't local
	
	if has_input: # if currently getting input from the user (typing)
		if (event is InputEventKey) and (event.is_pressed()):
			# TODO: condense this? KEY_ENTER may be different from ENTER, and KEY_BACKSPACE may be different from BACKSPACE
			var unicode = event.unicode
			if event.keycode == KEY_ENTER: unicode = ENTER # carriage return (enter)
			elif event.keycode == KEY_BACKSPACE: unicode = BACKSPACE
			elif event.keycode == KEY_TAB: unicode = TAB
			add_input_char(unicode)

# updates the chat box with the given unicode character
func add_input_char(unicode):
	match unicode:
		BACKSPACE: input_chars.pop_back() # backspace
		ENTER: # handle carriage return
			return_input()
			return
		# TODO: handle tabs/newlines more properly by clipping input_chars based on length of chars_to_draw
		_: if character_is_printable(unicode): input_chars.append(unicode) # only add printable characters
	
	display_input_chars()
	input_chars = input_chars.slice(0, 1+last_ascii_index-len(prefix))

# set input chars to the ASCII-array equivalent of the given string
func initialize_input_chars(initial_input_string):
	input_chars = Array(initial_input_string.to_utf8_buffer())

# display the current array of input characters in the TypeBox
func display_input_chars():
	var string = PackedByteArray(input_chars).get_string_from_ascii() 
	set_string(string)

func set_string(string):
	super(prefix+string)
	self.string = string

# DON'T send reliable updates on set_chars!
func set_ascii_chars(ascii_chars):
	super(ascii_chars)

func interact(other_object=null, info=null):
	if not is_local: return # don't do anything if this ChatBox isn't local to this machine
	capture_input(other_object) # take input from other object
	update_color(typing_color)

# return input to the last object that takes input
func return_input():
	update_color(base_color)
	super()
