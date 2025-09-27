extends CharacterDisplay
class_name UnitCard

const IMAGE_PATH ="res://Assets/Fonts/font_atlas_fixed_grid_baseline_fixed.png"

func _ready():
	# Load image from file
	var image := Image.new()
	var err := image.load(IMAGE_PATH)
	if err != OK:
		push_error("Failed to load image: %s" % IMAGE_PATH)
		return

	# Show image on display
	display_image(image)

	# Optional: move display back so it's visible in the 3D scene
	#display.translation = Vector3(-display.pixel_width / 2, -display.pixel_height / 2, -10)
