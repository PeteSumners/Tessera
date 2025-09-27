extends TextBox
class_name ShaderTextBox

func _init():
	super()
	grid_x_len = 16  # Set reasonable display dimensions
	grid_y_len = 8

func load_materials():
	var material = ShaderMaterial.new()
	material.shader = preload("res://shaders/basic_text_shader.gdshader")
	
	# Load character atlas
	var char_image = Image.load_from_file("res://Textures/ascii_atlas.png")
	if char_image:
		var char_texture = ImageTexture.create_from_image(char_image)
		material.set_shader_parameter("albedo_texture", char_texture)
	
	# Load color atlas
	var color_image = Image.load_from_file("res://Textures/color_atlas.png")
	if color_image:
		var color_texture = ImageTexture.create_from_image(color_image)
		material.set_shader_parameter("color_texture", color_texture)
		
	transparent_material = material

func _ready():
	super()
	set_string("Hello, World!")
