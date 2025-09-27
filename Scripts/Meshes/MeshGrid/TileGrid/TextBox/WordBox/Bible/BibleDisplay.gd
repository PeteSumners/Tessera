extends BookDisplay
class_name BibleDisplay

# color verse numbers gray
func color_verses():
	ascii_char_colors.clear()
	var next_verse_start = 0
	var next_verse_text_start = get_next_verse_text_start(next_verse_start)
	while(next_verse_start != -1):
		set_ascii_char_color(next_verse_start, MeshTextColor.GRAY)
		set_ascii_char_color(next_verse_text_start, MeshTextColor.WHITE)
		next_verse_start = get_next_verse_start(next_verse_start+1)
		next_verse_text_start = get_next_verse_text_start(next_verse_start)
	grid_data_changed = true

func set_chars_to_draw():
	color_verses()
	super()

# get the next verse's starting index, from "from"
func get_next_verse_start(from):
	return string.find("\n", from)

# get the next verse's starting text index, starting from "from"
func get_next_verse_text_start(from):
	return string.find("\t", string.find(":", from))
