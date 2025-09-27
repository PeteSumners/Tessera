# like a normal TextBox, except text is processed as words instead of individual characters
extends ShaderTextBox
class_name WordBox

var last_char_was_newline = false
var last_whitespace_index = -1

func _init():
	super()
#	set_string("afffffffffuffff	a")

func set_chars_to_draw():
	last_char_was_newline = false
	last_whitespace_index = -1
	super()

# only separates words based on white space (not punctuation). this will make things much simpler for you. 
# TODO: only hyphenate a word if it's long. but only hyphenate between alphanumeric chars (not punctuation/symbols). 
# adds character as part of a word instead of as an individual character
func add_character(ascii_value):
	# pure spaces between lines don't get displayed, but multiple tabs do
	# tabs and newlines trigger a newline in the WordBox, but spaces don't
	# when at the start of a line, whitespace doesn't get displayed unless a newline has been triggered
#	if current_draw_index >= max_chars: return false # don't draw past the box's character capacity!
	
	var should_add_character = true
#	if at_start_of_line() and (not last_char_was_newline) and (character_is_space(ascii_value) or character_is_tab(ascii_value)): should_add_character = false
#	if at_start_of_line() and (not last_char_was_newline) and character_is_newline(ascii_value): 
#		last_char_was_newline = true
#		should_add_character = false
	
	if at_start_of_line():
		if not character_is_whitespace(ascii_value):
			move_or_hyphenate_current_word(ascii_value)
		elif character_is_whitespace(ascii_value):
			if at_start_of_line() and (not last_char_was_newline): should_add_character = false
				
	if should_add_character: super.add_character(ascii_value)
	
	if character_is_whitespace(ascii_value): last_whitespace_index = current_draw_index-1
	last_char_was_newline = character_is_newline(ascii_value)
	
	return true
#	last_char_was_newline = false
#	if character_is_tab(ascii_value) or character_is_newline(ascii_value):
#		if at_start_of_line(): last_char_was_newline = true

# makes the current word start at the start of the current line OR hyphenates it across lines
# assumes you're in the middle of drawing the current word, just before writing another of its characters
# next_char is the char that will be added to the word
func move_or_hyphenate_current_word(next_char):
	var word_start_index = last_whitespace_index+1
	var word_length = current_draw_index - word_start_index
	var word_is_long = word_length >= grid_x_len
	
	if word_is_long: # hyphenate word if it's long AND the next character won't be punctuation
		if not character_is_punctuation(next_char): super.add_character(HYPHEN)
	else: # shift word if it isn't that long
		for i in range(word_start_index, word_start_index+word_length):
			super.add_character(get_char_to_draw(i)) # no special processing here: just add an individual character, ignoring the characters around it
			set_char_to_draw(i, SPACE)
