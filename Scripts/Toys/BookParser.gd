extends Node

const book_names = ["Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy"]

# Called when the node enters the scene tree for the first time.
func _ready():
	var test_text = get_chapter_content("Exodus", 1)
#	var test_find = test_text.find("Exodus 1:1")
#	print(test_find)
#	print(test_text.substr(test_find,200))
	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# returns the text of the given chapter, or, if it can't be found, some help text
func get_chapter_content(book_name, chapter_number):
	var file = FileAccess.open("res://Bible/bible.txt", FileAccess.READ)
	var text = file.get_as_text()
	var first_verse_prefix = " 1:1" # start of a given book
	var book_index = book_names.find(book_name)
	var next_book_index = book_index + 1
	var book_end = len(text)
	if next_book_index < len(book_names): book_end = text.find(book_names[next_book_index] + first_verse_prefix)
	var book_start = text.find(book_name + first_verse_prefix)
	print(text.substr(book_start, book_end-book_start))
	

# display a help message to help the user find a valid book
func get_book_help():
	var help_string = "Valid books: "
	var last_book_index = len(book_names)-1
	for i in range(last_book_index):
		help_string += book_names[i] + ", "
	help_string += book_names[last_book_index]
	return help_string
