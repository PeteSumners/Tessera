extends Node
#class_name SurfaceToolManager (handled automatically by Godot 4's autoload feature!)

const DIR_TO_TILE = [2, 3, 0, 1, 4, 5]  # +x=east(2), -x=west(3), +y=top(0), -y=bottom(1), +z=north(4), -z=south(5)
const NUM_DIRECTIONS = 6

const FACE_NAMES = ["top", "bottom", "east", "west", "north", "south"]
const ATLAS_WIDTH_MULTIPLIER = 6  # One tile per face

# Static surface tools for each material type
static var surface_tools = {}
static var materials = {}

# Initialization flag
static var initialized = false

func _ready():
	initialize()

static func initialize():
	if initialized:
		return
	
	initialized = true
	setup_material_and_tools()

static func setup_material_and_tools():
	# Load the shader
	var shader = preload("res://shaders/pixelated_glass.gdshader")
	
	# Setup materials and surface tools for each voxel type and direction
	for voxel_type in Voxel.VoxelType.values():
		if voxel_type == Voxel.VoxelType.AIR:
			continue
			
		# Voxel name for file paths
		var voxel_name = Voxel.get_voxel_name(voxel_type).to_lower()
		
		# Load the 6 face textures and create atlas (shared per voxel type)
		var atlas_image = create_face_atlas(voxel_name)
		var atlas_texture = ImageTexture.create_from_image(atlas_image)
		
		for dir_index in range(NUM_DIRECTIONS):
			var key = str(voxel_type) + "_" + str(dir_index)
			
			# Create and setup material
			var material = ShaderMaterial.new()
			material.shader = shader
			material.set_shader_parameter("tiling_scale", 1.0)  # Repeats per block unit; adjust as needed
			material.set_shader_parameter("texture_sheet_width", ATLAS_WIDTH_MULTIPLIER)
			material.set_shader_parameter("texture_map", atlas_texture)
			material.set_shader_parameter("face_tile_index", DIR_TO_TILE[dir_index])  # Selects atlas tile
			
			if voxel_type == Voxel.VoxelType.GLASS:
				material.render_priority = -1
				
			# Store material
			materials[key] = material
			
			# Create and store surface tool
			var st = MeshHelper.get_new_surface_tool()
			surface_tools[key] = st

static func create_face_atlas(voxel_name: String) -> Image:
	var face_images = []
	var tile_size = 0  # Will detect from first valid texture
	
	# Load each face texture
	for face in FACE_NAMES:
		var texture_path = "res://Assets/Textures/Blocks/%s_%s.png" % [voxel_name, face]
		var texture = load(texture_path) as Texture2D
		var face_image: Image
		if texture:
			face_image = texture.get_image()
			if tile_size == 0:
				tile_size = face_image.get_width()  # Assume square; use height if needed
		else:
			# Fallback: transparent black if missing
			push_warning("Missing texture: %s. Using fallback." % texture_path)
			face_image = Image.create(16, 16, false, Image.FORMAT_RGBA8)  # Default 16x16; adjust if needed
			face_image.fill(Color(0, 0, 0, 0))
			if tile_size == 0:
				tile_size = 16
		
		# Convert to RGBA8 to match atlas format
		face_image.convert(Image.FORMAT_RGBA8)
		face_images.append(face_image)
	
	# Create horizontal atlas strip
	var atlas = Image.create(tile_size * ATLAS_WIDTH_MULTIPLIER, tile_size, false, Image.FORMAT_RGBA8)
	for i in range(ATLAS_WIDTH_MULTIPLIER):
		atlas.blit_rect(face_images[i], Rect2(0, 0, tile_size, tile_size), Vector2i(i * tile_size, 0))
	
	return atlas

static func get_surface_tool(voxel_type: int, dir_index: int) -> SurfaceTool:
	if not initialized:
		initialize()
	var key = str(voxel_type) + "_" + str(dir_index)
	return surface_tools[key]

static func get_material(voxel_type: int, dir_index: int) -> Material:
	if not initialized:
		initialize()
	var key = str(voxel_type) + "_" + str(dir_index)
	return materials[key]

static func reset_surface_tools():
	for key in surface_tools:
		var st = surface_tools[key]
		MeshHelper.reset_surface_tool(st)
