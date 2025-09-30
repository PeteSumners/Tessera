extends Node3D
class_name AnimatedTextDisplay

# Text rendering (static until content changes)
var text_layer: Image
var text_texture: ImageTexture

# Animation rendering (per-frame)
var animation_layer: Image
var animation_texture: ImageTexture

# Configuration
var cols: int = 80
var visible_rows: int = 25
var glyph_width: int
var glyph_height: int
var content_width: int
var viewport_height: int

# Content
var content_lines: PackedStringArray = []
var line_colors: Array[Color] = []
var content_height: int

# Scrolling
var scroll_offset: float = 0.0
var max_scroll: float = 0.0
var scroll_velocity: float = 0.0
var scroll_friction: float = 5.0

# Mesh and material
var mesh_instance: MeshInstance3D
var shader_material: ShaderMaterial

func _init(columns: int = 80, rows: int = 25):
	cols = columns
	visible_rows = rows
	
	glyph_width = AtlasHelper.get_glyph_width()
	glyph_height = AtlasHelper.get_glyph_height()
	
	content_width = cols * glyph_width
	viewport_height = visible_rows * glyph_height
	
	# Create layers
	text_layer = Image.create(content_width, viewport_height, false, Image.FORMAT_RGBA8)
	animation_layer = Image.create(content_width, viewport_height, false, Image.FORMAT_RGBA8)
	
	text_texture = ImageTexture.create_from_image(text_layer)
	animation_texture = ImageTexture.create_from_image(animation_layer)
	
	setup_mesh_and_shader()

func setup_mesh_and_shader():
	var phys_width = content_width * 0.01
	var phys_height = viewport_height * 0.01
	
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(phys_width, 0, 0),
		Vector3(phys_width, -phys_height, 0),
		Vector3(0, -phys_height, 0)
	])
	
	var normals = PackedVector3Array([
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
		Vector3(0, 0, -1)
	])
	
	var uvs = PackedVector2Array([
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(1, 1),
		Vector2(0, 1)
	])
	
	var indices = PackedInt32Array([0, 1, 2, 0, 2, 3])
	
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh
	
	shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://shaders/animated_scrolling_text.gdshader")
	shader_material.set_shader_parameter("text_layer", text_texture)
	shader_material.set_shader_parameter("animation_layer", animation_texture)
	mesh_instance.material_override = shader_material

func set_content(lines: PackedStringArray):
	content_lines = lines
	line_colors.clear()
	for i in range(lines.size()):
		line_colors.append(Color.WHITE)
	render_text_layer()

func set_colored_content(lines: PackedStringArray, colors: Array[Color]):
	content_lines = lines
	line_colors = colors
	render_text_layer()

func render_text_layer():
	content_height = content_lines.size() * glyph_height
	max_scroll = max(0.0, content_height - viewport_height)
	
	# Expand text layer if needed
	if text_layer.get_height() < content_height:
		text_layer = Image.create(content_width, content_height, false, Image.FORMAT_RGBA8)
		text_texture = ImageTexture.create_from_image(text_layer)
		shader_material.set_shader_parameter("text_layer", text_texture)
	
	text_layer.fill(Color.BLACK)
	
	for line_idx in range(content_lines.size()):
		var line = content_lines[line_idx]
		var y_pos = line_idx * glyph_height
		var color = line_colors[line_idx] if line_idx < line_colors.size() else Color.WHITE
		
		for char_idx in range(min(line.length(), cols)):
			var char = line[char_idx]
			var x_pos = char_idx * glyph_width
			
			var glyph = AtlasHelper.get_glyph_image(char)
			if glyph:
				blit_colored_glyph(text_layer, glyph, x_pos, y_pos, color)
	
	text_texture.update(text_layer)
	shader_material.set_shader_parameter("content_height_ratio", 
		float(content_height) / float(viewport_height))

func blit_colored_glyph(target: Image, glyph: Image, dest_x: int, dest_y: int, color: Color):
	for y in range(glyph.get_height()):
		for x in range(glyph.get_width()):
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

func update_animation_layer():
	# Clear animation layer - subclasses override to draw animations
	animation_layer.fill(Color(0, 0, 0, 0))

func commit_animation_layer():
	animation_texture.update(animation_layer)

func scroll_by_pixels(pixels: float):
	scroll_offset += pixels
	scroll_offset = clamp(scroll_offset, 0.0, max_scroll)
	update_scroll_shader()

func scroll_by_lines(lines: int):
	scroll_by_pixels(lines * glyph_height)

func update_scroll_shader():
	var normalized_offset = scroll_offset / float(content_height) if content_height > 0 else 0.0
	shader_material.set_shader_parameter("scroll_offset", normalized_offset)

func _process(delta):
	# Update animations
	update_animation_layer()
	commit_animation_layer()
	
	# Smooth scrolling
	if abs(scroll_velocity) > 0.1:
		scroll_by_pixels(scroll_velocity * delta)
		scroll_velocity = lerp(scroll_velocity, 0.0, scroll_friction * delta)

func start_scroll(velocity: float):
	scroll_velocity = velocity
