extends Display3D
class_name BibleReader3D

var scroll: ScrollContainer
var text: RichTextLabel

func _ready():
	super()
	setup_reader()
	load_passage("Genesis", 1)

func setup_reader():
	# ScrollContainer for smooth scrolling
	scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_ui(scroll)
	
	# RichTextLabel for formatted text
	text = RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.custom_minimum_size.x = resolution.x
	scroll.add_child(text)
	
	# Styling
	text.add_theme_font_size_override("normal_font_size", 24)
	text.add_theme_color_override("default_color", Color.WHITE)
	text.add_theme_constant_override("line_separation", 8)

func load_passage(book: String, chapter: int):
	var content = BibleHelper.get_chapter_text(book, chapter, 2)
	text.text = format_verses(content)
	scroll.scroll_vertical = 0

func format_verses(raw: String) -> String:
	var lines = raw.split("\n")
	var formatted: PackedStringArray = []
	
	for line in lines:
		if ":" in line:
			var parts = line.split(" ", false, 2)
			if parts.size() >= 3:
				formatted.append("[color=gray]%s %s[/color] %s" % [parts[0], parts[1], parts[2]])
			else:
				formatted.append(line)
		else:
			formatted.append(line)
	
	return "\n".join(formatted)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll.scroll_vertical += 30
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll.scroll_vertical -= 30
