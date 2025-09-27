extends TypeBox
class_name BibleReader

var bible_display

# TODO: text box to describe controls for players
# TODO: save world state for different chapters of the Bible to tell a story. Remember: voxel games allow players to build together. Build a community that builds worlds for these chapters: like a virtual pop-up-book. Maybe even use specific verses for this. IDK. 
# TODO: test each book's chapters to make sure they fit in the BookDisplay
# TODO: chapter help for each book based on text-finding functions
const book_names = ["Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra", "Nehemiah", "Esther", "Job", "Psalm", "Proverbs", "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel", "Hosea", "Joel", "Amos", "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi", "Matthew", "Mark", "Luke", "John", "Acts", "Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians", "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians", "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews", "James", "1 Peter", "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation"]

var text = ""
const first_verse_suffix = ":1"
const first_chapter_first_verse_suffix = " 1" + first_verse_suffix # starting verse of any given book

func _init():
	super()
	grid_x_len = 24
	grid_y_len = 2
	text = FileAccess.get_file_as_string("res://Bible/kjv_ascii.txt")

func get_book_chapter_count(book_name):
	var book_content = get_book_content(book_name)
	var last_verse = book_content.substr(book_content.rfind(book_name))
	var last_chapter = last_verse.substr(len(book_name)+1)
	last_chapter = last_chapter.substr(0,last_chapter.find(":"))
	return int(last_chapter)

# return the character index of the given book's start in the Bible
func get_book_start(book_name):
	return text.find(book_name + first_chapter_first_verse_suffix)

# return the character index of the given book's end in the Bible
func get_book_end(book_name):
	var book_index = book_names.find(book_name)
	if book_index == -1: return -1 # book not found
	var next_book_index = book_index + 1
	var book_end = len(text)
	if next_book_index < len(book_names):
		book_end = text.find(book_names[next_book_index] + first_chapter_first_verse_suffix)
	return book_end

func book_chapter_string(book_name, chapter):
	return book_name + " " + str(chapter) + first_verse_suffix
	
# assume chapter is an int
func get_chapter_start(book_name, chapter):
	return text.find(book_chapter_string(book_name, chapter))

# assume chapter is an int
func get_chapter_end(book_name, chapter):
	var book_chapter_count = get_book_chapter_count(book_name)
	if chapter == book_chapter_count: # last chapter
		return get_book_end(book_name)
	else:
		var next_chapter = chapter + 1
		return text.find(book_chapter_string(book_name, next_chapter))

# whether the given book_name (a string) has the given chapter (an int)
func book_has_chapter(book_name, chapter):
	return chapter in range(1, 1+get_book_chapter_count(book_name))

# assume chapter is an int!
func get_chapter_content(book_name, chapter):
	if not book_has_chapter(book_name, chapter): return "Chapter " + str(chapter) + " not found in " + book_name + "!"
	var chapter_start = get_chapter_start(book_name, chapter)
	var chapter_end = get_chapter_end(book_name, chapter)
	return text.substr(chapter_start, chapter_end-chapter_start)

# returns the text of the given chapter, or, if it can't be found, some help text
func get_book_content(book_name):
	var book_start = get_book_start(book_name)
	var book_end = get_book_end(book_name)
	if (book_start != -1) and (book_end != -1):
		return text.substr(book_start, book_end-book_start)
	else:
		return get_book_list()

# display a help message to help the user find a valid chapter for a given book
func get_book_help(book_name):
	var num_chapters = get_book_chapter_count(book_name)
	var help_string = book_name + " has " + str(num_chapters) + " chapters. Please input a chapter number after the book name. Example: \"" + book_name + " 1\"."
	return help_string

# display a help message to help the user find a valid book
func get_book_list():
	var help_string = "Valid books: "
	var last_book_index = len(book_names)-1
	for i in range(last_book_index):
		help_string += book_names[i] + ", "
	help_string += book_names[last_book_index]
	return help_string

func _ready():
	# TODO: why no work?
	bible_display = BibleDisplay.new()
	bible_display.position = Vector3.DOWN * (grid_y_len+1)
	add_child(bible_display)
	bible_display.set_string(get_chapter_content("Genesis", 1)) # default display
	bible_display.color_verses()

# parse what is (hopefully) a book and chapter number
func parse_input(string):
	# first, try to find the book
	var book_name = string
	var tokens = string.split(" ")
	var chapter = int(tokens[len(tokens)-1]) # last token
	var found_book = book_names.has(book_name)
	if not found_book: # try finding the book by excluding the last token
		var num_tokens = len(tokens)
		var book_tokens = tokens.slice(0,num_tokens-1)
		book_name = " ".join(book_tokens)
		found_book = book_names.has(book_name)
	
	if found_book:
		if chapter in range(1, 1+get_book_chapter_count(book_name)): # input has chapter AND book
			display(get_chapter_content(book_name, chapter))
			bible_display.color_verses()
		else: display(get_book_help(book_name)) # input only has book
	else:
		display(get_book_list()) # default

# display the given string
func display(display_string):
	bible_display.set_string(display_string)
	reliable_data_changed = true

# return input to the last object that takes input
# (called when ENTER is pressed)
func return_input():
	parse_input(string)
	super()

func _input(event):
	super(event)
	if not is_local: return
	if (event is InputEventKey) and (event.is_pressed()):
		match event.keycode:
			KEY_DOWN:
				increment_start_line(1)
			KEY_UP:
				increment_start_line(-1)

func increment_start_line(increment):
	bible_display.increment_start_line(increment)
	reliable_data_changed = true

func generate_reliable_data():
	var other_network_data = super()
	return [other_network_data, bible_display.generate_reliable_data()]

# update this object's (fast) state from the given array of network data
func update_from_reliable_data(network_data):
	if network_data == null: return # don't try to update with no data
	super(network_data[0])
	bible_display.update_from_reliable_data(network_data[1]) # update!
