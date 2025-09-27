extends Node

# =======================================
# SingleGlyphDisplay.gd
# =======================================
#
# PURPOSE:
# Uses FontAtlasHelper to grab and display
# a single character as a TextureRect.
#
# =======================================

# Import your helper
const FontAtlasHelper = preload("res://Scripts/Meshes/MeshGrid/PixelDisplay/AtlasHelper.gd")

func _ready():
	# === Create helper instance ===
	var helper = FontAtlasHelper.new()
	
	# === Get glyph image for character 'A' ===
	var glyph_img = helper.get_glyph_image("A")
	
	if glyph_img == null:
		push_error("Failed to get glyph image for character 'A'")
		return

	# === Convert Image to ImageTexture ===
	var tex = ImageTexture.create_from_image(glyph_img)

	# === Create TextureRect to display ===
	var tr = TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	# === Optional: Set position or anchors ===
	tr.position = Vector2(100, 100)

	# === Add to scene tree ===
	add_child(tr)
