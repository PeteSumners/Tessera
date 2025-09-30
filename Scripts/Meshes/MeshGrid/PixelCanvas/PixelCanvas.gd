extends Node3D
class_name PixelCanvas

var width: int
var height: int
var physical_scale: float = 0.01  # meters per pixel

var image: Image
var texture: ImageTexture
var mesh_instance: MeshInstance3D
var material: StandardMaterial3D

func _init(w: int = 100, h: int = 100, scale: float = 0.01):
	width = w
	height = h
	physical_scale = scale
	
	# Create image
	image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	
	# Create texture
	texture = ImageTexture.create_from_image(image)
	
	# Setup mesh and material
	setup_mesh()

func setup_mesh():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	var phys_width = width * physical_scale
	var phys_height = height * physical_scale
	
	# Create quad
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
	
	# Create material
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

func set_pixel(x: int, y: int, color: Color):
	if x >= 0 and x < width and y >= 0 and y < height:
		image.set_pixel(x, y, color)

func get_pixel(x: int, y: int) -> Color:
	if x >= 0 and x < width and y >= 0 and y < height:
		return image.get_pixel(x, y)
	return Color.BLACK

func fill_rect(rect: Rect2i, color: Color):
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			set_pixel(x, y, color)

func clear(color: Color = Color.BLACK):
	image.fill(color)

func blit_image(source: Image, dest_pos: Vector2i):
	image.blit_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), dest_pos)

func update_texture():
	texture.update(image)

func get_image() -> Image:
	return image
