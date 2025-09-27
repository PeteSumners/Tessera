extends Node

# ============================
# FontAtlasRenderer.gd
# ============================
#
# Loads:
# - font_atlas_fixed_grid_baseline_fixed.png
# - font_atlas_fixed_grid_baseline_fixed_metadata.json
# - font_atlas_fixed_grid_baseline_fixed_fontinfo.json
#
# Renders arbitrary strings as a TextureRect in your scene.
#
# ============================

func _ready():
	var test_string = "The quick brown fox jumps over the lazy dog.\nПривет мир! Ёжик ёлка ЁЁ.\nMixed ABC Привет Ёё."
	display_rendered_image(AtlasHelper.render_string(test_string))

func display_rendered_image(rendered_image : Image):
	# Create a PixelDisplay node
	var display = TerminalDisplay.new()
	
	# Send the rendered Image to PixelDisplay's display_image() method
	display.display_image(rendered_image)
	
	# Add PixelDisplay to the scene tree (so it shows up)
	add_child(display)
	
	# Optional: position display if needed, for example:
	# display.translation = Vector3(-rendered_image.get_width() / 2, -rendered_image.get_height() / 2, -10)
