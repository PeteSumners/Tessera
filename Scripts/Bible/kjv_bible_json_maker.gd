extends Node

func _ready():
	var bible_path = "res://Bible/kjv_ascii.txt"
	var text = load_file(bible_path)
	var bible_json = parse_bible(text)
	save_json("res://Bible/kjv.json", bible_json)
	print("✅ Bible parsed with correct book names → res://Bible/kjv.json")

# --- Helpers ---

func load_file(path: String) -> String:
	var f = FileAccess.open(path, FileAccess.READ)
	var content = f.get_as_text()
	f.close()
	return content

func save_json(path: String, data):
	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  ")) # pretty-print
	f.close()

func parse_bible(text: String) -> Array:
	var bible: Array = []  # ordered list of books
	var lines = text.split("\n", false)

	var current_book = ""
	var current_chapter = ""
	var book_entry = {}
	var chapter_entry = {}

	for line in lines:
		var parts = line.split("\t", false)
		if parts.size() < 2:
			continue

		var ref = parts[0]   # e.g. "1 Chronicles 27:1"
		var verse_text = parts[1]

		# --- Find book name and chapter:verse ---
		var colon_idx = ref.find(":")
		if colon_idx == -1:
			continue

		var space_idx = ref.rfind(" ", colon_idx)
		if space_idx == -1:
			continue

		var book = ref.substr(0, space_idx)   # full book name
		var rest = ref.substr(space_idx + 1)  # e.g. "27:1"

		var chap_verse = rest.split(":")
		if chap_verse.size() != 2:
			continue
		var chapter = chap_verse[0]
		var verse = chap_verse[1]

		# --- Handle new book ---
		if book != current_book:
			if current_book != "":
				if current_chapter != "":
					book_entry["chapters"].append(chapter_entry)
				bible.append(book_entry)
			book_entry = {
				"book": book,
				"chapters": []
			}
			current_book = book
			current_chapter = ""

		# --- Handle new chapter ---
		if chapter != current_chapter:
			if current_chapter != "":
				book_entry["chapters"].append(chapter_entry)
			chapter_entry = {
				"chapter": int(chapter),
				"verses": []
			}
			current_chapter = chapter

		# --- Add verse ---
		chapter_entry["verses"].append({
			"verse": int(verse),
			"text": verse_text
		})

	# Push last chapter and book
	if current_chapter != "":
		book_entry["chapters"].append(chapter_entry)
	if current_book != "":
		bible.append(book_entry)

	return bible
