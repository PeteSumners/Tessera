extends CompositeDisplay
class_name UnitCard

var unit_name: String
var unit_stats: Dictionary

func _init():
	super(200, 300, 0.01)

func load_unit(data: Dictionary):
	unit_name = data.get("name", "Unknown")
	unit_stats = data
	
	create_base_layer()
	create_content_layer()

func create_base_layer():
	var base = Image.create(width, height, false, Image.FORMAT_RGBA8)
	base.fill(Color(0.1, 0.1, 0.15, 1.0))
	
	# Draw border
	draw_border(base, Rect2i(0, 0, width, height), Color(0.3, 0.3, 0.4), 2)
	
	# Load portrait if available
	if unit_stats.has("portrait_path"):
		var portrait = load_portrait(unit_stats.portrait_path)
		if portrait:
			base.blit_rect(portrait, Rect2i(Vector2i.ZERO, portrait.get_size()), Vector2i(10, 10))
	
	set_layer("base", base)

func create_content_layer():
	var content = Image.create(width, height, false, Image.FORMAT_RGBA8)
	content.fill(Color(0, 0, 0, 0))
	
	# Render stats text
	var y_offset = 120
	render_text_to_image(content, "Name: " + unit_name, 10, y_offset, Color.WHITE)
	y_offset += 20
	
	if unit_stats.has("attack"):
		render_text_to_image(content, "ATK: " + str(unit_stats.attack), 10, y_offset, Color.RED)
		y_offset += 20
	
	if unit_stats.has("defense"):
		render_text_to_image(content, "DEF: " + str(unit_stats.defense), 10, y_offset, Color.BLUE)
		y_offset += 20
	
	if unit_stats.has("hp"):
		render_text_to_image(content, "HP: " + str(unit_stats.hp), 10, y_offset, Color.GREEN)
	
	set_layer("content", content)

func render_text_to_image(target: Image, text: String, x: int, y: int, color: Color):
	var glyph_w = AtlasHelper.get_glyph_width()
	
	for i in range(text.length()):
		var char = text[i]
		var glyph = AtlasHelper.get_glyph_image(char)
		if glyph:
			blit_colored_glyph(target, glyph, x + i * glyph_w, y, color)

func blit_colored_glyph(target: Image, glyph: Image, dest_x: int, dest_y: int, color: Color):
	for y in range(glyph.get_height()):
		for x in range(glyph.get_width()):
			if dest_x + x >= target.get_width() or dest_y + y >= target.get_height():
				continue
			var pixel = glyph.get_pixel(x, y)
			if pixel.a > 0.01:
				var brightness = (pixel.r + pixel.g + pixel.b) / 3.0
				var colored = Color(
					color.r * brightness,
					color.g * brightness,
					color.b * brightness,
					pixel.a
				)
				target.set_pixel(dest_x + x, dest_y + y, colored)

func draw_border(target: Image, rect: Rect2i, color: Color, thickness: int):
	for t in range(thickness):
		var inner_rect = rect.grow(-t)
		# Top
		for x in range(inner_rect.position.x, inner_rect.position.x + inner_rect.size.x):
			target.set_pixel(x, inner_rect.position.y, color)
		# Bottom
		for x in range(inner_rect.position.x, inner_rect.position.x + inner_rect.size.x):
			target.set_pixel(x, inner_rect.position.y + inner_rect.size.y - 1, color)
		# Left
		for y in range(inner_rect.position.y, inner_rect.position.y + inner_rect.size.y):
			target.set_pixel(inner_rect.position.x, y, color)
		# Right
		for y in range(inner_rect.position.y, inner_rect.position.y + inner_rect.size.y):
			target.set_pixel(inner_rect.position.x + inner_rect.size.x - 1, y, color)

func load_portrait(path: String) -> Image:
	if FileAccess.file_exists(path):
		var img = Image.new()
		var err = img.load(path)
		if err == OK:
			return img
	return null
