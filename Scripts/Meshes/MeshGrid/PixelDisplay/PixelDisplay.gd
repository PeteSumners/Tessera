extends PhysicsObject
class_name PixelDisplay

var pixel_width: int = 10
var pixel_height: int = 10

var physical_scale: float = .1  # meters per pixel

var shader_material = null
var mesh_instance = null

var needs_texture_update := false

var img := Image.new()
var texture := ImageTexture.new()
var raw_data := PackedByteArray()

var pixel_update_batch: Array = []

func _init(pix_width := 10, pix_height := 10, phys_scale := .01):
	pixel_width = pix_width
	pixel_height = pix_height
	physical_scale = phys_scale

	setup_mesh_and_material()


func get_physical_width() -> float:
	return pixel_width * physical_scale

func get_physical_height() -> float:
	return pixel_height * physical_scale

func setup_image_and_texture():
	raw_data.resize(pixel_width * pixel_height * 4)
	for i in range(raw_data.size()):
		raw_data[i] = 0  # Transparent black

	img = Image.create_from_data(pixel_width, pixel_height, false, Image.FORMAT_RGBA8, raw_data)
	texture = ImageTexture.new()
	texture.create_from_image(img)
	shader_material.set_shader_parameter("pixel_texture", texture)

func setup_mesh_and_material():
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		add_child(mesh_instance)
	
	var arr_mesh = ArrayMesh.new()
	
	var width = get_physical_width()
	var height = get_physical_height()

	var vertices = PackedVector3Array([
		Vector3(0, 0, 0),             # top-left
		Vector3(width, 0, 0),         # top-right
		Vector3(width, -height, 0),   # bottom-right
		Vector3(0, -height, 0),       # bottom-left
	])


	var normals = PackedVector3Array([
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
	])

	var uvs = PackedVector2Array([
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(1, 1),
		Vector2(0, 1),
	])

	var indices = PackedInt32Array([0, 1, 2, 2, 3, 0])

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = arr_mesh

	if shader_material == null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = preload("res://shaders/pixel_display.gdshader")
	mesh_instance.material_override = shader_material

	setup_image_and_texture()

func resize(w: int, h: int, phys_scale: float=physical_scale):
	if w == pixel_width and h == pixel_height:
		return
	pixel_width = w
	pixel_height = h
	setup_mesh_and_material() # physical resize

func set_pixel(x: int, y: int, color: Array):
	pixel_update_batch.append([x, y, color])
	needs_texture_update = true

func apply_pixel_batch():
	if pixel_update_batch.size() == 0:
		return

	for update in pixel_update_batch:
		var x = update[0]
		var y = update[1]
		var c = update[2]
		set_pixel_direct(x, y, Color(c[0], c[1], c[2], c[3]))

	pixel_update_batch.clear()
	
	# After setting pixels, update image and texture
	img.set_data(pixel_width, pixel_height, false, Image.FORMAT_RGBA8, raw_data)
	texture.set_image(img)

func set_pixel_direct(x: int, y: int, color: Color):
	if x < 0 or x >= pixel_width or y < 0 or y >= pixel_height:
		return
	var index = (y * pixel_width + x) * 4
	raw_data[index + 0] = int(clamp(color.r * 255, 0, 255))
	raw_data[index + 1] = int(clamp(color.g * 255, 0, 255))
	raw_data[index + 2] = int(clamp(color.b * 255, 0, 255))
	raw_data[index + 3] = int(clamp(color.a * 255, 0, 255))

func get_pixel(x: int, y: int) -> Array:
	if x < 0 or x >= pixel_width or y < 0 or y >= pixel_height:
		return [0.0, 0.0, 0.0, 0.0]
	var index = (y * pixel_width + x) * 4
	return [
		raw_data[index + 0] / 255.0,
		raw_data[index + 1] / 255.0,
		raw_data[index + 2] / 255.0,
		raw_data[index + 3] / 255.0,
	]

func clear_display():
	for i in range(raw_data.size()):
		raw_data[i] = 0
	img.set_data(pixel_width, pixel_height, false, Image.FORMAT_RGBA8, raw_data)
	texture.set_image(img)

func draw_rect(x: int, y: int, width: int, height: int, color: Array):
	for cy in range(y, min(y + height, pixel_height)):
		for cx in range(x, min(x + width, pixel_width)):
			set_pixel(cx, cy, color)

func get_pixel_dimensions() -> Vector2:
	return Vector2(pixel_width, pixel_height)

func to_normalized_coords(x: int, y: int) -> Vector2:
	return Vector2(
		(float(x) + 0.5) / float(pixel_width),
		(float(y) + 0.5) / float(pixel_height)
	)

func get_center() -> Vector2:
	return Vector2(
		(pixel_width / 2.0) - 0.5,
		(pixel_height / 2.0) - 0.5
	)

func _process(delta):
	if needs_texture_update:
		apply_pixel_batch()
		needs_texture_update = false

func display_image(image: Image):
	if image.is_empty():
		push_error("Cannot display: Image is empty.")
		return

	resize(image.get_width(), image.get_height())

	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)

	raw_data = image.get_data()

	var expected_size = pixel_width * pixel_height * 4
	if raw_data.size() != expected_size:
		push_error("Image data size mismatch. Expected %d bytes, got %d bytes." % [expected_size, raw_data.size()])
		return

	img.set_data(pixel_width, pixel_height, false, Image.FORMAT_RGBA8, raw_data)
	texture.set_image(img)

func blit_image_region(src_image: Image, src_rect: Rect2, dest_pos: Vector2i):
	for y in range(int(src_rect.size.y)):
		var dest_y = dest_pos.y + y
		if dest_y < 0 or dest_y >= pixel_height:
			continue
		for x in range(int(src_rect.size.x)):
			var dest_x = dest_pos.x + x
			if dest_x < 0 or dest_x >= pixel_width:
				continue
			var c = src_image.get_pixel(int(src_rect.position.x) + x, int(src_rect.position.y) + y)
			set_pixel(dest_x, dest_y, [c.r, c.g, c.b, c.a])
