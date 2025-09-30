extends Node
# =======================================
# BibleHelper.gd (singleton)
# =======================================

var bible_data: Array = []

func _ready() -> void:
	# Optional: auto-load on startup
	load_bible("res://Bible/kjv.json")


# --- Load Bible JSON ---
func load_bible(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f:
		bible_data = JSON.parse_string(f.get_as_text())
		f.close()
	else:
		push_error("Bible file not found at %s" % path)


# --- Lookup helpers ---
func get_book(book_name: String) -> Dictionary:
	for book in bible_data:
		if book["book"].to_lower() == book_name.to_lower():
			return book
	return {}

func get_chapter(book_name: String, chapter_num: int) -> Dictionary:
	var book := get_book(book_name)
	if book.is_empty():
		return {}
	for chap in book["chapters"]:
		if chap["chapter"] == chapter_num:
			return chap
	return {}

func get_verse(book_name: String, chapter_num: int, verse_num: int) -> String:
	var chapter := get_chapter(book_name, chapter_num)
	if chapter.is_empty():
		return ""
	for v in chapter["verses"]:
		if v["verse"] == verse_num:
			return v["text"]
	return ""


# --- Chapter as text ---
# mode = 1 -> whole chapter continuous
# mode = 2 -> verse-per-line with refs
func get_chapter_text(book_name: String, chapter_num: int, mode: int = 1) -> String:
	var chapter := get_chapter(book_name, chapter_num)
	if chapter.is_empty():
		return ""
	
	var output := ""
	if mode == 1:
		# Book name + chapter header
		output += "%s %d\n\n" % [book_name, chapter_num]
		for v in chapter["verses"]:
			output += v["text"] + " "
	elif mode == 2:
		for v in chapter["verses"]:
			output += "%s %d:%d %s\n" % [book_name, chapter_num, v["verse"], v["text"]]
	return output.strip_edges()
