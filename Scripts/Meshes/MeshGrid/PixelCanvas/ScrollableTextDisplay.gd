extends Node3D
class_name ScrollableTextDisplay

# Configuration
var cols: int = 80
var visible_rows: int = 25
var glyph_width: int = 8
var glyph_height: int = 16

# Blend modes
enum BlendMode {
	NORMAL,      # Standard alpha blend
	ADDITIVE,    # Add colors together
	SUBTRACTIVE  # Subtract colors
}

# Content
var content_lines: PackedStringArray = []
var line_colors: Array[Color] = []
var line_blend_modes: Array[BlendMode] = []  # NEW: Per-line blend modes

# Rendering
var content_texture: ImageTexture
var content_width: int
var content_height: int
var viewport_height: int

# Scrolling
var scroll_offset: float = 0.0
var max_scroll: float = 0.0
var scroll_velocity: float = 0.0
var scroll_friction: float = 5.0

# Mesh and material
var mesh_instance: MeshInstance3D
var shader_material: ShaderMaterial

# Add new member variables at the top of the class
var total_content_height: int = 0  # Full document height in pixels
var render_offset: int = 0          # Top of rendered window in document space
var last_render_start_line: int = -1  # Track when to re-render

func _init(columns: int = 80, rows: int = 25):
	cols = columns
	visible_rows = rows
	
	glyph_width = AtlasHelper.get_glyph_width()
	glyph_height = AtlasHelper.get_glyph_height()
	
	content_width = cols * glyph_width
	viewport_height = visible_rows * glyph_height
	
	setup_mesh_and_shader()

func setup_mesh_and_shader():
	var glyph_w = AtlasHelper.get_glyph_width()  # 14
	var glyph_h = AtlasHelper.get_glyph_height() # 32
	
	# Calculate pixel dimensions
	content_width = cols * glyph_w      # 80 * 14 = 1120 pixels
	viewport_height = visible_rows * glyph_h  # 25 * 32 = 800 pixels
	
	# CRITICAL: Scale each dimension by its pixel count with SAME scale factor
	# This preserves the natural aspect ratio of the glyphs
	var pixel_scale = 0.01  # 1cm per pixel (both x and y)
	
	var phys_width = content_width * pixel_scale    # 1120 * 0.01 = 11.2m
	var phys_height = viewport_height * pixel_scale # 800 * 0.01 = 8.0m
	
	# Now physical aspect ratio matches pixel aspect ratio:
	# phys: 11.2:8.0 = 1.4:1
	# pixels: 1120:800 = 1.4:1
	# glyphs: (80*14):(25*32) = 1120:800 = 1.4:1 ✓
	
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
	shader_material.shader = load("res://shaders/scrollable_text.gdshader")
	mesh_instance.material_override = shader_material

func set_content(lines: PackedStringArray):
	content_lines = lines
	line_colors.clear()
	line_blend_modes.clear()
	for i in range(lines.size()):
		line_colors.append(Color.WHITE)
		line_blend_modes.append(BlendMode.NORMAL)
	render_content()

func set_colored_content(lines: PackedStringArray, colors: Array[Color]):
	content_lines = lines
	line_colors = colors
	line_blend_modes.clear()
	for i in range(lines.size()):
		line_blend_modes.append(BlendMode.NORMAL)
	render_content()

# NEW: Full control over colors and blend modes
func set_styled_content(lines: PackedStringArray, colors: Array[Color], blend_modes: Array[BlendMode]):
	content_lines = lines
	line_colors = colors
	line_blend_modes = blend_modes
	render_content()

# ScrollableTextDisplay.render_content()
func render_content():
	var buffer_lines = 5
	total_content_height = content_lines.size() * glyph_height
	max_scroll = max(0.0, total_content_height - viewport_height)
	
	# Calculate which lines to render
	var start_line = max(0, int(scroll_offset / glyph_height) - buffer_lines)
	var end_line = min(content_lines.size(), start_line + visible_rows + buffer_lines * 2)
	
	render_offset = start_line * glyph_height
	content_height = (end_line - start_line) * glyph_height
	last_render_start_line = start_line
	
	var content_image = Image.create(content_width, content_height, false, Image.FORMAT_RGBA8)
	content_image.fill(Color.BLACK)
	
	# Render only visible range
	for line_idx in range(start_line, end_line):
		var line = content_lines[line_idx]
		var y_pos = (line_idx - start_line) * glyph_height
		var color = line_colors[line_idx] if line_idx < line_colors.size() else Color.WHITE
		var blend_mode = line_blend_modes[line_idx] if line_idx < line_blend_modes.size() else BlendMode.NORMAL
		
		for char_idx in range(min(line.length(), cols)):
			var char = line[char_idx]
			var x_pos = char_idx * glyph_width
			
			var glyph = AtlasHelper.get_glyph_image(char)
			if glyph:
				blit_colored_glyph(content_image, glyph, x_pos, y_pos, color, blend_mode)
	
	if content_texture == null:
		content_texture = ImageTexture.create_from_image(content_image)
	else:
		content_texture.update(content_image)
	
	shader_material.set_shader_parameter("content_texture", content_texture)
	update_scroll_shader()
	
	# DEBUG: Save rendered image to check if squishing happens CPU-side
	content_image.save_png("res://debug_content_image.png")

func blit_colored_glyph(target: Image, glyph: Image, dest_x: int, dest_y: int, color: Color, blend_mode: BlendMode = BlendMode.NORMAL):
	for y in range(glyph.get_height()):
		for x in range(glyph.get_width()):
			if dest_x + x >= target.get_width() or dest_y + y >= target.get_height():
				continue
				
			var pixel = glyph.get_pixel(x, y)
			if pixel.a < 0.01:
				continue
			
			var brightness = (pixel.r + pixel.g + pixel.b) / 3.0
			var fg_color = Color(
				color.r * brightness,
				color.g * brightness,
				color.b * brightness,
				color.a * pixel.a
			)
			
			var bg_color = target.get_pixel(dest_x + x, dest_y + y)
			var final_color = bg_color
			
			match blend_mode:
				BlendMode.NORMAL:
					# Standard alpha blend
					final_color = bg_color.lerp(fg_color, fg_color.a)
				BlendMode.ADDITIVE:
					# Add colors together
					final_color.r = clamp(bg_color.r + fg_color.r * fg_color.a, 0.0, 1.0)
					final_color.g = clamp(bg_color.g + fg_color.g * fg_color.a, 0.0, 1.0)
					final_color.b = clamp(bg_color.b + fg_color.b * fg_color.a, 0.0, 1.0)
					final_color.a = clamp(bg_color.a + fg_color.a, 0.0, 1.0)
				BlendMode.SUBTRACTIVE:
					# Subtract colors
					final_color.r = clamp(bg_color.r - fg_color.r * fg_color.a, 0.0, 1.0)
					final_color.g = clamp(bg_color.g - fg_color.g * fg_color.a, 0.0, 1.0)
					final_color.b = clamp(bg_color.b - fg_color.b * fg_color.a, 0.0, 1.0)
					final_color.a = clamp(bg_color.a - fg_color.a, 0.0, 1.0)
			
			target.set_pixel(dest_x + x, dest_y + y, final_color)

func scroll_by_pixels(pixels: float):
	scroll_offset += pixels
	scroll_offset = clamp(scroll_offset, 0.0, max_scroll)
	
	# Check if we need to re-render due to scrolling beyond buffer
	var current_line = int(scroll_offset / glyph_height)
	var render_start = render_offset / glyph_height
	var render_end = render_start + (content_height / glyph_height)
	var buffer_threshold = 3  # Re-render when within 3 lines of buffer edge
	
	if current_line < render_start + buffer_threshold or current_line > render_end - buffer_threshold - visible_rows:
		render_content()
	else:
		update_scroll_shader()

func scroll_by_lines(lines: int):
	scroll_by_pixels(lines * glyph_height)

func update_scroll_shader():
	if content_height <= 0 or viewport_height <= 0:
		return
	
	# Calculate position within the rendered window
	var local_offset = scroll_offset - render_offset
	var normalized = local_offset / float(viewport_height)
	
	shader_material.set_shader_parameter("scroll_offset", normalized)
	shader_material.set_shader_parameter("content_height_ratio", 
		float(content_height) / float(viewport_height))

func _process(delta):
	if abs(scroll_velocity) > 0.1:
		scroll_by_pixels(scroll_velocity * delta)
		scroll_velocity = lerp(scroll_velocity, 0.0, scroll_friction * delta)

func start_scroll(velocity: float):
	scroll_velocity = velocity
