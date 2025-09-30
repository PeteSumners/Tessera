extends Node3D
class_name CompositeDisplay

var width: int
var height: int
var physical_scale: float = 0.01

# Layers
var layers: Dictionary = {}  # name -> Image
var layer_order: PackedStringArray = ["base", "content", "overlay"]

# Final composite
var composite_image: Image
var composite_texture: ImageTexture

# Mesh
var mesh_instance: MeshInstance3D
var material: StandardMaterial3D

var needs_recomposite: bool = false

func _init(w: int = 256, h: int = 256, scale: float = 0.01):
	width = w
	height = h
	physical_scale = scale
	
	composite_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	composite_texture = ImageTexture.create_from_image(composite_image)
	
	setup_mesh()

func setup_mesh():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	var phys_width = width * physical_scale
	var phys_height = height * physical_scale
	
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
	
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.albedo_texture = composite_texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

func set_layer(layer_name: String, image: Image):
	layers[layer_name] = image.duplicate()
	needs_recomposite = true

func update_layer(layer_name: String, image: Image):
	set_layer(layer_name, image)

func get_layer(layer_name: String) -> Image:
	return layers.get(layer_name, null)

func clear_layer(layer_name: String):
	if layers.has(layer_name):
		layers[layer_name].fill(Color(0, 0, 0, 0))
		needs_recomposite = true

func recomposite():
	composite_image.fill(Color(0, 0, 0, 0))
	
	# Composite layers in order
	for layer_name in layer_order:
		if layers.has(layer_name):
			blend_layer(composite_image, layers[layer_name])
	
	composite_texture.update(composite_image)
	needs_recomposite = false

func blend_layer(target: Image, source: Image):
	for y in range(min(target.get_height(), source.get_height())):
		for x in range(min(target.get_width(), source.get_width())):
			var src_pixel = source.get_pixel(x, y)
			if src_pixel.a > 0.01:
				var dst_pixel = target.get_pixel(x, y)
				var blended = dst_pixel.lerp(src_pixel, src_pixel.a)
				target.set_pixel(x, y, blended)

func _process(_delta):
	if needs_recomposite:
		recomposite()
