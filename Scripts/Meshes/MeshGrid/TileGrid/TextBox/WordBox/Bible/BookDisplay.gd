# displays Bible text!
extends WordBox
class_name BookDisplay

func _init():
	super()
	grid_x_len = 32
	grid_y_len = 32

func _ready():
	super()
	set_string("asdf!")
#	if is_local: display_chapter("Genesis", 1)
#	else: set_string("not local!")

# increments current_start_line by the given number of lines
func increment_start_line(increment):
	set_start_line(current_start_line + increment)

# TODO...
# -----------------------------------------------------
# use mesh text color to make red letters (for Gospels). 
func make_red_letters():
	pass

# remove verse numbers from the given string to display the Bible as text only. 
func remove_verse_numbers():
	pass
