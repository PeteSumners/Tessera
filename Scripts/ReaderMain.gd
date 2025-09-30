extends Node3D

var terrain: PerlinTerrainGrid
var spectator: Node3D
var bible_reader: BibleReader3D
var skybox: Node3D

# Terrain settings
const TERRAIN_SIZE = 64
const TERRAIN_HEIGHT = 16

# Spawn settings
const SPAWN_HEIGHT = 10.0
const READER_DISTANCE = 3.0
const READER_HEIGHT_OFFSET = -0.5

func _ready():
	setup_skybox()
	setup_terrain()
	setup_spectator()
	setup_bible_reader()
	lock_cursor()

func setup_skybox():
	skybox = Node3D.new()
	add_child(skybox)
	
	var world_env = WorldEnvironment.new()
	skybox.add_child(world_env)
	
	var env = Environment.new()
	world_env.environment = env
	
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.2, 0.4, 0.8)
	sky_material.sky_horizon_color = Color(0.8, 0.9, 1.0)
	sky_material.sky_curve = 0.5
	sky.sky_material = sky_material
	
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_energy = 0.0
	env.ambient_light_color = Color(0, 0, 0, 1)
	env.ambient_light_sky_contribution = 0.0
	env.sdfgi_read_sky_light = false
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.fog_enabled = false
	env.glow_enabled = false

func setup_terrain():
	terrain = PerlinTerrainGrid.new()
	add_child(terrain)
	
	# Override size
	terrain.grid_x_len = TERRAIN_SIZE
	terrain.grid_y_len = TERRAIN_HEIGHT
	terrain.grid_z_len = TERRAIN_SIZE
	
	# Generate flat grassland
	generate_flat_grassland()

func generate_flat_grassland():
	terrain.clear_grid()
	
	var grass_height = 3
	
	for x in range(TERRAIN_SIZE):
		for z in range(TERRAIN_SIZE):
			terrain.set_voxel([x, grass_height, z], Voxel.VoxelType.GRASS)
			
			for y in range(grass_height):
				terrain.set_voxel([x, y, z], Voxel.VoxelType.DIRT)
	
	terrain.grid_data_changed = true

func setup_spectator():
	spectator = Node3D.new()
	add_child(spectator)
	
	# Add camera
	var camera = Camera3D.new()
	spectator.add_child(camera)
	
	# Load and attach Spectator script
	var spectator_script = load("res://Scripts/Movement/Spectator.gd")
	spectator.set_script(spectator_script)
	spectator.camera_node_path = spectator.get_path_to(camera)
	
	# Position in center of terrain
	var center_x = TERRAIN_SIZE / 2.0
	var center_z = TERRAIN_SIZE / 2.0
	spectator.position = Vector3(center_x, SPAWN_HEIGHT, center_z)

func setup_bible_reader():
	bible_reader = BibleReader3D.new()
	add_child(bible_reader)
	
	# Position in front of spectator
	var forward = -spectator.global_transform.basis.z
	bible_reader.global_position = spectator.global_position + forward * READER_DISTANCE
	bible_reader.global_position.y += READER_HEIGHT_OFFSET
	
	# Face the camera
	bible_reader.look_at(spectator.global_position, Vector3.UP)
	bible_reader.rotate_y(PI)

func lock_cursor():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta):
	# Optional: update bible reader to follow player
	# update_bible_reader_position()
	pass

func update_bible_reader_position():
	var forward = -spectator.global_transform.basis.z
	var target_pos = spectator.global_position + forward * READER_DISTANCE
	target_pos.y = spectator.global_position.y + READER_HEIGHT_OFFSET
	
	bible_reader.global_position = bible_reader.global_position.lerp(target_pos, 0.1)
	bible_reader.look_at(spectator.global_position, Vector3.UP)
	bible_reader.rotate_y(PI)
