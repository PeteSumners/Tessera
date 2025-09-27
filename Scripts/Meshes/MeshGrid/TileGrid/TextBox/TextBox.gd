# TODO: optimize network updates: only update data that changes!

# TODO: display back AND front of TileTextBoxes? maybe just have them always face the camera
# TODO: timed text (for subtitles, lyrics, or electronic storybooks)
extends TileGrid
class_name TextBox

# ASCII codes
const BACKSPACE=8
const TAB=9
const NEWLINE=10
const ENTER=13
const SPACE=32
const HYPHEN=45
const UNDERSCORE=95
const DELETE=127

const ascii_sheet_width = 10 # width/length of the ASCII character sheet (in tiles)
const color_sheet_width = 3 # width/length of the ASCII color sheet (in tiles)

var string = "" # the current string
var current_start_line = 0 # current start line to display text from
var ascii_chars: PackedByteArray # array of ASCII characters to display
var chars_to_draw : PackedByteArray # actual array of ASCII characters displayed in this TextBox

# helper variables for text processing
var current_draw_index = 0 # index to draw the next character at
var last_ascii_index = -1 # index in ascii_chars of the last-drawn character
const tab_length = 3 # number of spaces in a tab

enum MeshTextColor {
	BLACK,
	BLUE,
	GREEN,
	CYAN,
	RED,
	MAGENTA,
	YELLOW,
	WHITE,
	GRAY
}

var current_color = MeshTextColor.WHITE # color of character currently being drawn
var ascii_char_colors = {} # ascii char colors
var draw_char_colors = {} # colors for the characters to draw

var display_debug_colors = false # whether to display color to assist with text debugging

func _init():
	super()
	grid_x_len = 8 # maximum allowed number of characters per line
	grid_y_len = 3 # number of lines to draw in the TextBox
	ascii_chars = PackedByteArray([])
	chars_to_draw = PackedByteArray([])

# Called when the node enters the scene tree for the first time.
func _ready():
	grid_data_changed = true # do this to start text display
	activate()

func add_collision_shapes():
	return # no collision for text boxes!

func generate_mesh_data():
	#set_chars_to_draw()
	#scroll_characters() (TODO)
	draw_characters()

# test the text box
func test():
	ascii_chars.resize(0)
	for i in range(32,128):
		ascii_chars.append(i)
	grid_data_changed = true

# update the text box using a string
func set_string(string):
	self.string = string
	current_start_line = 0 # always default to displaying strings from their start
	set_ascii_chars(string.to_ascii_buffer())
	set_chars_to_draw()

# set the current start line to the new start line 
# also bounds input
func set_start_line(new_start_line):
	current_start_line = new_start_line
	current_start_line = max(0,current_start_line) # at least from 
	current_start_line = min(current_start_line, (current_draw_index-1)/grid_x_len)

# TODO: remove add_buffer_spaces when you're sure you don't need this code anymore
## adds buffer spaces to the given string to display certain kinds of whitespace and to make words readable in the TextBox
#func add_buffer_spaces(string):
#	var split_string = string.split(" ")
#	var buffered_string = ""
#
#	var current_line = ""
#	var current_line_word_count = 0 # number of little words in the current line
#	for word in split_string: # loop through all words
#		if current_line_word_count != 0: current_line += " " # add spaces back between words
#		current_line += word #little_word
#		current_line_word_count += 1
#
#		if len(current_line) > chars_per_line: # if there isn't enough room...
#			if current_line_word_count > 1: # if it's the last word that tipped string length over the edge, move the last word to the next line, and end the current line
#				current_line = current_line.substr(0,len(current_line)-len(word)-1) # remove word (and a space) from current_line
#				buffered_string += buffer_line_with_spaces(current_line)
#				current_line = word # move little word to next line
#			current_line_word_count = 1
#
#			while len(current_line) > chars_per_line: # if one word is taking up all the space, then use hyphens to split it up across lines
#				buffered_string += current_line.substr(0, chars_per_line-1) + "-"
#				current_line = current_line.substr(chars_per_line-1)
#
#	buffered_string += current_line # last line! 
#	buffered_string = buffer_string_with_spaces(buffered_string, num_chars()) # maket the final string the right length
#
#	return buffered_string

# return the given string but of the given length with the end buffered with spaces
func buffer_string_with_spaces(string, length):
	string = string.substr(0, length) # clip string to max length
	while len(string) < length: # add spaces to fill strings that are too short
		string += " "
	return string

# return the given string but of length chars_per_line with the end buffered with spaces
func buffer_line_with_spaces(string):
	return buffer_string_with_spaces(string, grid_x_len)

# gets the number of characters to draw in this TextBox
func num_chars():
	var num_chars = grid_y_len * grid_x_len
	return num_chars

# set ascii chars directly, and update the text box
func set_ascii_chars(ascii_chars):
	self.ascii_chars = ascii_chars.duplicate()

# update the color of all text in the text box
# TODO: make this reliable data
func update_color(mesh_text_color):
	ascii_char_colors = {0:mesh_text_color}
	draw_char_colors = ascii_char_colors.duplicate()
	grid_data_changed = true

# writes ascii_chars to chars_to_draw, but as individual, directly-printable characters (without any special ASCII codes)
func set_chars_to_draw():
	grid_data_changed = true
	reset_chars_to_draw()
	current_draw_index = 0 # start at the beginning of the text box
	last_ascii_index = -1 # track the index of the last-drawn character
	
	for i in range(0,len(ascii_chars)):
		var character = ascii_chars[i]
		if ascii_char_colors.has(i):
			set_char_color(current_draw_index, ascii_char_colors[i])
		if not add_character(character): break
		last_ascii_index += 1

# reset chars_to_draw to an array of spaces of length num_chars()
func reset_chars_to_draw():
	chars_to_draw.resize(num_chars())
	chars_to_draw.fill(SPACE)
	draw_char_colors.clear()

# adds a character given its index in the text box and its ASCII value
# returns false if character addition failed
func add_character(ascii_value):
#	if current_draw_index >= max_chars: # don't add chars past chars_to_draw's capacity
#		return false
	
	if character_is_tab(ascii_value): add_tab()
	elif character_is_newline(ascii_value): add_newline()
	else: # add character as normal
		set_char_to_draw(current_draw_index, ascii_value)
		current_draw_index += 1
	return true

# directly set character to draw, with no effect on current_draw_index
# fills chars_to_draw with spaces if a resize is needed
func set_char_to_draw(index, value):
	var previous_size = chars_to_draw.size()
	if index >= previous_size:
		chars_to_draw.resize(previous_size*2) # exponential growth, O(log(N)) calls
		for i in range(previous_size, len(chars_to_draw)): chars_to_draw.set(i, SPACE) # fill with spaces up to new size
	chars_to_draw.set(index, value)

# move current_draw_index to next tab
func add_tab():
	snap_current_draw_index(tab_length)

# "snaps" the current draw index to the next multiple of snap_length, measured from the start of the current line
func snap_current_draw_index(snap_length):
	var old_line_index = current_draw_index / grid_x_len
	
	var index_in_line = current_draw_index % grid_x_len
	var overshot = index_in_line % snap_length
	current_draw_index += snap_length - overshot
	
	# in case tab goes past the current line
	var new_line_index = current_draw_index / grid_x_len
	var went_to_next_line = old_line_index < new_line_index
	if went_to_next_line: current_draw_index = new_line_index * grid_x_len

# move current_draw_index to next line
func add_newline():
	snap_current_draw_index(grid_x_len)

# add a SPACE character
func add_space():
	add_character(SPACE)

func at_start_of_tab():
	return (current_draw_index % tab_length) == 0

func at_start_of_line():
	return (current_draw_index % grid_x_len) == 0

static func character_is_numeric(ascii_value):
	return ascii_value in range(48,58)

static func character_is_upper_alpha(ascii_value):
	return ascii_value in range(65,91)

static func character_is_lower_alpha(ascii_value):
	return ascii_value in range(97, 123)

# returns true iff the given ascii value represents a letter or a number
static func character_is_alphanumeric(ascii_value):
	return character_is_numeric(ascii_value) or character_is_upper_alpha(ascii_value) or character_is_lower_alpha(ascii_value) or (ascii_value==UNDERSCORE) # consider underscores alphanumeric characters

static func character_is_newline(ascii_value):
	return (ascii_value == ENTER) or (ascii_value == NEWLINE)

static func character_is_space(ascii_value):
	return ascii_value == SPACE

# tests whether the given character is a whitespace character
static func character_is_whitespace(ascii_value):
	return character_is_space(ascii_value) or character_is_tab(ascii_value) or character_is_newline(ascii_value)

static func character_is_tab(ascii_value):
	return ascii_value == TAB

# includes underscores
static func character_is_punctuation(ascii_value):
	return ((ascii_value in range(32,48)) or (ascii_value in range(58,65)) or (ascii_value in range(91,97)) or (ascii_value in range(123,127)))

static func character_is_printable(ascii_value):
	return character_is_alphanumeric(ascii_value) or character_is_whitespace(ascii_value) or character_is_punctuation(ascii_value)

func get_char_to_draw(index):
	if index in range(0,len(chars_to_draw)):
		return chars_to_draw[index]
	else:
		return SPACE

func set_ascii_char_color(index, value):
	ascii_char_colors[index] = value

func set_char_color(index, value):
	draw_char_colors[index] = value
	# draw_char_colors isn't networked!

# get the index of the current character to start drawing from
func get_current_start_index():
	return current_start_line * grid_x_len

# draws characters to mesh using chars_to_draw
# start_line: line number to start drawing characters from
func draw_characters():
	var start_index = get_current_start_index()
	current_color = get_start_color()
	
	# TODO: add line number to start drawing from
	for i in range(0, num_chars()):
		var char_index = start_index+i
		var char = get_char_to_draw(char_index)
		var tile_index = get_character_tile_index(char)
		if draw_char_colors.has(char_index):
			current_color = draw_char_colors[char_index]
		if display_debug_colors: # switch colors depending on ascii value
			if char == 58: current_color = (1+current_color)%len(MeshTextColor)
#			if (i % grid_x_len) % tab_length == 0: mesh_text_color = MeshTextColor.CYAN
#			else: mesh_text_color = MeshTextColor.WHITE
		MeshHelper.draw_quad(transparent_surface_tool, calculate_character_vertices(i), calculate_character_uvs(tile_index), calculate_color_uvs(current_color)) # draw a character

# gets the MeshTextColor to start drawing with
func get_start_color():
	# basically, do rfind on dictionary keys
	var start_index = get_current_start_index()
	var sorted_keys = draw_char_colors.keys()
	sorted_keys.sort()
	var start_color_index = sorted_keys.find(start_index) # index in keys
	if start_color_index == -1: # not directly found
		start_color_index = sorted_keys.bsearch(start_index)-1 # use bsearch to find the nearest key
	if start_color_index == -1: return MeshTextColor.WHITE # default color if no color found
	else: return draw_char_colors[sorted_keys[start_color_index]]

# calculates the index in the character tile map for a character given its ASCII value
func get_character_tile_index(ascii_value):
	return ascii_value - 32

# calculates character bounding vertices given the character's index in the text box
func calculate_character_vertices(index):
	var x = -(index % grid_x_len)
	var y = -int(index / grid_x_len)
	return calculate_tile_vertices([x, y, 0])

# calculates texture uvs for an ASCII character with the given id (index) 
static func calculate_character_uvs(index):
	return MeshHelper.calculate_tile_uvs(index, ascii_sheet_width)

# calculates texture uvs for the given MeshTextColor (color)
static func calculate_color_uvs(color):
	return MeshHelper.calculate_tile_uvs(color, color_sheet_width)

func load_materials():
	transparent_material = load("res://Textures/Text Material.tres")


# TODO-------------------------
## 
#func scroll_characters():
#	var lines_available_to_draw = len(chars_to_draw) / chars_per_line
#	self.preferred_start_line = min(start_line, lines_available_to_draw - num_lines_to_draw)
#	pass # TODO

# update text box's start line (in order to display chars_to_draw from the given starting line)
# also triggers a mesh update
#func set_start_line(start_line):
#	# TODO: support for negative start lines (infinite scrolling)
#	self.start_line = start_line
#	grid_data_changed = true
