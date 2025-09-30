extends ScrollableTextDisplay
class_name BibleReader

const book_names = ["Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", 
	"Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", 
	"1 Chronicles", "2 Chronicles", "Ezra", "Nehemiah", "Esther", "Job", "Psalm", 
	"Proverbs", "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah", "Lamentations", 
	"Ezekiel", "Daniel", "Hosea", "Joel", "Amos", "Obadiah", "Jonah", "Micah", 
	"Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi", "Matthew", 
	"Mark", "Luke", "John", "Acts", "Romans", "1 Corinthians", "2 Corinthians", 
	"Galatians", "Ephesians", "Philippians", "Colossians", "1 Thessalonians", 
	"2 Thessalonians", "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews", 
	"James", "1 Peter", "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation"]

var bible_text: String
var current_book: String = "Genesis"
var current_chapter: int = 1
var word_wrap_enabled: bool = true

func load_chapter(book: String, chapter: int):
	current_book = book
	current_chapter = chapter
	
	var chapter_text = get_chapter_content(book, chapter)
	
	# Apply word wrapping
	var lines: PackedStringArray
	if word_wrap_enabled:
		lines = TextUtils.word_wrap(chapter_text, cols)
	else:
		lines = chapter_text.split("\n")
	
	var colored_lines = PackedStringArray()
	var colors: Array[Color] = []
	
	for line in lines:
		colored_lines.append(line)
		# Color verse numbers gray
		if line.contains(":"):
			colors.append(Color(0.6, 0.6, 0.6))
		else:
			colors.append(Color.WHITE)
	
	set_colored_content(colored_lines, colors)
	
	# Reset scroll to top
	scroll_offset = 0.0
	update_scroll_shader()

func _init():
	super(80, 25)

func _ready():
	load_bible()

func load_bible():
	bible_text = FileAccess.get_file_as_string("res://Bible/kjv_ascii.txt")
	if bible_text:
		load_chapter(current_book, current_chapter)
	else:
		push_error("Failed to load Bible text file")

func get_chapter_content(book: String, chapter: int) -> String:
	var chapter_start = find_chapter_start(book, chapter)
	if chapter_start == -1:
		return get_error_message(book, chapter)
	
	var chapter_end = find_chapter_end(book, chapter)
	return bible_text.substr(chapter_start, chapter_end - chapter_start)

func find_chapter_start(book: String, chapter: int) -> int:
	var search_string = book + " " + str(chapter) + ":1"
	return bible_text.find(search_string)

func find_chapter_end(book: String, chapter: int) -> int:
	var next_chapter_start = find_chapter_start(book, chapter + 1)
	if next_chapter_start != -1:
		return next_chapter_start
	
	# Last chapter of book - find next book
	var book_index = book_names.find(book)
	if book_index < book_names.size() - 1:
		var next_book = book_names[book_index + 1]
		var next_book_start = find_chapter_start(next_book, 1)
		if next_book_start != -1:
			return next_book_start
	
	return bible_text.length()

func get_error_message(book: String, chapter: int) -> String:
	return "Chapter " + str(chapter) + " not found in " + book

func next_chapter():
	load_chapter(current_book, current_chapter + 1)

func prev_chapter():
	if current_chapter > 1:
		load_chapter(current_book, current_chapter - 1)

# BibleReader._input()
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_DOWN:
			scroll_by_pixels(1.0)  # 1 pixel down
		elif event.keycode == KEY_UP:
			scroll_by_pixels(-1.0)  # 1 pixel up
		elif event.keycode == KEY_PAGEDOWN:
			scroll_by_lines(visible_rows)
		elif event.keycode == KEY_PAGEUP:
			scroll_by_lines(-visible_rows)
		elif event.keycode == KEY_RIGHT:
			next_chapter()
		elif event.keycode == KEY_LEFT:
			prev_chapter()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_by_pixels(3.0)  # 3 pixels per wheel notch
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_by_pixels(-3.0)
