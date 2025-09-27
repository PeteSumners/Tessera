#TODO: change light level depending on voxel update, flood-fill light, and then update mesh instead of regenerating ALL light data
extends MeshGrid
class_name CubeGrid

var voxel_data = []
var light_data = []
var ambient_lights = []

const texture_sheet_width = 4 # width of the voxel texture file in tiles
const light_map_width = 4

const ambient_light_level = 15

var grid_z_len = 16 # 3D grids have depth

const DIRECTION_NORMALS_ARRAY = [
	[1, 0, 0],   # 0: +x
	[-1, 0, 0],  # 1: -x
	[0, 1, 0],   # 2: +y
	[0, -1, 0],  # 3: -y
	[0, 0, 1],   # 4: +z
	[0, 0, -1]   # 5: -z
]

func _init():
	super()

func _ready():
	voxel_data.resize(get_voxel_count())
	light_data.resize(get_voxel_count())
	ambient_lights.resize(get_voxel_count())
	
	generate_voxel_data() # data initialization is not well-suited for multithreading with mesh updates, so just do it all at once
	generate_light_data()

# overrides MeshGrid.add_collision_shapes()
func add_collision_shapes():
	add_collision_boxes()

# add a bunch of cubes associated with each voxel.
# TODO: only add if voxel is exposed
func add_collision_boxes():
	for x in range(0, grid_x_len):
		for y in range(0, grid_y_len):
			for z in range(0, grid_z_len):
				var coordinates = [x,y,z]
				if Voxel.is_solid(get_voxel(coordinates)): # this voxel is solid
					for adjacent_coordinates in get_surrounding_coordinates(coordinates): # check neighbors
						if not Voxel.is_solid(get_voxel(adjacent_coordinates)): # neighbor is not solid
							var cube_coordinates = coordinates.duplicate()
							for i in range(0,len(cube_coordinates)): 
								cube_coordinates[i] += .5 # shift by .5 in all directions to move box collider to center of voxel
							add_collision_box(cube_coordinates) # put collision cubes on boundaries between solid/non-solid voxels
							break # don't bother checking more neighbors if you already have a collision box

# return the number of voxels (volumetric pixels) in this CubeGrid
func get_voxel_count():
	return grid_x_len * grid_y_len * grid_z_len

# generation instructions!
func generate_voxel_data():
	generate_test_data()

# empty the grid so that it's all air
func clear_grid():
	voxel_data.fill(Voxel.VoxelType.AIR) # air is the default for now

# children should replace the following test code with actual terrain generation
func generate_test_data():
	clear_grid()
	
	# terrain generation stuff
	var fast_noise_lite = FastNoiseLite.new() # smooth_simplex noise by default
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	fast_noise_lite.seed = rng.randi()
	
	for x in range(0, grid_x_len):
		for y in range(0, grid_y_len):
			for z in range(0, grid_z_len):
#				var voxel_type = (((x*y*z) / 800)) % 4
#				set_voxel([x,y,z], voxel_type)
				var voxel_global_pos = to_global(Vector3(x,y,z))
				var noise_value = fast_noise_lite.get_noise_3dv(voxel_global_pos)
				noise_value = (noise_value + 1) / 2 # convert range from [-1, 1] to [0, 1]
				noise_value *= voxel_global_pos.y / grid_y_len # lower values at the bottom
				var voxel_type = Voxel.VoxelType.STONE
				if noise_value > .25: voxel_type = Voxel.VoxelType.AIR
				elif noise_value > .17: voxel_type = Voxel.VoxelType.GLASS
				elif noise_value > .1: voxel_type = Voxel.VoxelType.SAND
				voxel_type = Voxel.VoxelType.DIRT
				set_voxel([x,y,z],voxel_type)


func reset_light_data():
	ambient_lights.fill(false)
	light_data.fill(0)

func generate_light_data():
	reset_light_data()
	
	# First, set up ambient light from outside grid boundaries
	for x in range(0, grid_x_len):
		for y in range(0, grid_y_len):
			for z in range(0, grid_z_len):
				var coordinates = [x,y,z]
				if Voxel.is_transparent(get_voxel(coordinates)):
					# If this voxel is transparent and next to a boundary, it gets ambient light
					if x == 0 or x == grid_x_len-1 or y == 0 or y == grid_y_len-1 or z == 0 or z == grid_z_len-1:
						set_ambient_light(coordinates, true)
						set_light_level(coordinates, ambient_light_level)
	
	# Then, flood fill from light sources and ambient light
	for x in range(0, grid_x_len):
		for y in range(0, grid_y_len):
			for z in range(0, grid_z_len):
				var coordinates = [x,y,z]
				var voxel = get_voxel(coordinates)
				var light_level = max(
					get_light_level(coordinates),   # Either ambient or 0
					Voxel.get_light_source_level(voxel)  # Any light from the block itself
				)
				if light_level > 0:
					flood_fill_light(coordinates, light_level)

func flood_fill_light(start_coordinates, light_level):
	if not coordinates_within_bounds(start_coordinates):
		print("Tried to start flood_fill_light from outside the grid. Bad!")
		return
		
	var queue = []
	var visited = {}  
	var start_key = str(start_coordinates)  
	queue.push_back([start_coordinates, light_level])
	visited[start_key] = true

	while not queue.is_empty():
		var current = queue.pop_front()
		var current_coordinates = current[0]
		var current_light = current[1]
		
		# Set the light level for current block
		set_light_level(current_coordinates, current_light)
		
		# If current block is solid, stop propagating light through it
		if not Voxel.is_transparent(get_voxel(current_coordinates)):
			continue
			
		# Otherwise spread to neighbors
		for next_coordinates in get_surrounding_coordinates(current_coordinates):
			if not coordinates_within_bounds(next_coordinates):
				continue
				
			var next_key = str(next_coordinates)
			if next_key in visited:
				continue
				
			# Light decreases by 1 each block
			var next_light = current_light - 1
			if next_light <= 0:
				continue
				
			if Voxel.is_transparent(get_voxel(next_coordinates)):
				if get_light_level(next_coordinates) < next_light:
					queue.push_back([next_coordinates, next_light])
					visited[next_key] = true
					
	grid_data_changed = true

func generate_mesh_data():
	generate_light_data()
	grid_data_changed = false # unless data changes AGAIN (after updating light data), don't bother making another mesh
	
	for x in range(0,grid_x_len):
		for y in range(0,grid_y_len):
			for z in range(0,grid_z_len):
					draw_block_mesh([x,y,z])

# returns an array of coordinates that surround the given coordinates (+x,-x,+y,-y,+z,-z)
static func get_surrounding_coordinates(coordinates):
	return [
		[coordinates[0]+1, coordinates[1], coordinates[2]], # +x
		[coordinates[0]-1, coordinates[1], coordinates[2]], # -x
		[coordinates[0], coordinates[1]+1, coordinates[2]], # +y
		[coordinates[0], coordinates[1]-1, coordinates[2]], # -y
		[coordinates[0], coordinates[1], coordinates[2]+1], # +z
		[coordinates[0], coordinates[1], coordinates[2]-1]  # -z
	]

# return block verticechunk_coordinatess based on local coordinates (x,y,z)
static func calculate_block_vertices(coordinates):
	return [
		Vector3(coordinates[0], coordinates[1], coordinates[2]),
		Vector3(coordinates[0], coordinates[1], coordinates[2]+1),
		Vector3(coordinates[0], coordinates[1]+1, coordinates[2]),
		Vector3(coordinates[0], coordinates[1]+1, coordinates[2]+1),
		Vector3(coordinates[0]+1, coordinates[1], coordinates[2]),
		Vector3(coordinates[0]+1, coordinates[1], coordinates[2]+1),
		Vector3(coordinates[0]+1, coordinates[1]+1, coordinates[2]),
		Vector3(coordinates[0]+1, coordinates[1]+1, coordinates[2]+1)
	]

# draw the mesh for the block at coordinates (x,y,z)
# draw the mesh for the block at coordinates (x,y,z)
# draw the mesh for the block at coordinates (x,y,z)
func draw_block_mesh(coordinates):
	var surface_tool_to_use = surface_tool
	var voxel = get_voxel(coordinates)
	if (Voxel.is_transparent(voxel)):
		surface_tool_to_use = transparent_surface_tool
	if (voxel == 0): return # air
	var verts = calculate_block_vertices(coordinates)
	var surrounding_coordinates = get_surrounding_coordinates(coordinates)
	var mesh_data = [
		[surrounding_coordinates[0], [verts[4], verts[5], verts[7], verts[6]]], # +x face
		[surrounding_coordinates[1], [verts[1], verts[0], verts[2], verts[3]]], # -x face
		[surrounding_coordinates[2], [verts[2], verts[6], verts[7], verts[3]]], # +y face
		[surrounding_coordinates[3], [verts[1], verts[5], verts[4], verts[0]]], # -y face
		[surrounding_coordinates[4], [verts[5], verts[1], verts[3], verts[7]]], # +z face
		[surrounding_coordinates[5], [verts[0], verts[4], verts[6], verts[2]]]  # -z face
	]
	for face_index in range(mesh_data.size()):
		var faces_data = mesh_data[face_index]
		var other_coordinates = faces_data[0]
		var current_verts = faces_data[1]
		var other_voxel = get_voxel(other_coordinates)
		var other_voxel_transparent = Voxel.is_transparent(other_voxel)
		if (other_voxel_transparent and (other_voxel != voxel)): # other voxel is transparent and has a different id from this one: should display face
			var normal = DIRECTION_NORMALS_ARRAY[face_index]
			var face_uvs = MeshHelper.calculate_face_uvs(normal, 1.0, 1.0)
			MeshHelper.draw_quad(surface_tool_to_use, current_verts, face_uvs, calculate_light_uvs(other_coordinates))
			
# calculate uv coordinates in the lightmap for the given voxel coordinates
func calculate_light_uvs(coordinates):
	var light_level = get_light_level(coordinates)
	return MeshHelper.calculate_tile_uvs(light_level, light_map_width)

func get_light_level(coordinates):
	var voxel_index = calculate_voxel_index(coordinates)
	if voxel_index == -1: return ambient_light_level
	return light_data[voxel_index]

# sets the light level at the given coordinates
func set_light_level(coordinates, light_level):
	var voxel_index = calculate_voxel_index(coordinates)
	if voxel_index == -1: return # coordinates out of bounds
	light_data[voxel_index] = light_level
	grid_data_changed = true

func get_ambient_light(coordinates):
	var voxel_index = calculate_voxel_index(coordinates)
	if (voxel_index == -1): return true # ambient light if outside of chunk
	return ambient_lights[voxel_index]

# sets the voxel at the given coordinates to be an "ambient light" voxel
func set_ambient_light(coordinates, ambient_light):
	var voxel_index = calculate_voxel_index(coordinates)
	if (voxel_index == -1): return # don't try to set ambient light if index is invalid
	ambient_lights[calculate_voxel_index(coordinates)] = ambient_light

func calculate_block_uvs(coordinates):
	var id = get_voxel(coordinates)
	return MeshHelper.calculate_tile_uvs(id, texture_sheet_width)

# return the voxel id (always an int) for the voxel at x,y,z
func get_voxel(coordinates):
	var voxel_index = calculate_voxel_index(coordinates)
	if voxel_index == -1: return -1 # out of bounds, so invalid
	else:
		return int(voxel_data[voxel_index])

# sets voxel voxel_data for voxel at voxel coordinates(x,y,z)
func set_voxel(coordinates, value):
	var voxel_index = calculate_voxel_index(coordinates)
	if voxel_index == -1: return # coordinates out of bounds
	voxel_data[voxel_index] = int(value)
	grid_data_changed = true

# returns index (always an integer) in data arrays for the voxel at local coordinates (x, y, z)
# returns -1 if coordinates are out of bounds
func calculate_voxel_index(coordinates):
	if coordinates_within_bounds(coordinates):
		return int(coordinates[0]*grid_z_len*grid_y_len) + (coordinates[1]*grid_z_len) + (coordinates[2])
	return -1
	
func coordinates_within_bounds(coordinates):
	return coordinates_within_x_bounds(coordinates) and coordinates_within_y_bounds(coordinates) and coordinates_within_z_bounds(coordinates)

# bounds checks
func coordinates_within_x_bounds(coordinates):
	var x = int(coordinates[0])
	return (x < grid_x_len) and (x >= 0)

func coordinates_within_y_bounds(coordinates):
	var y = int(coordinates[1])
	return (y < grid_y_len) and (y >= 0)

func coordinates_within_z_bounds(coordinates):
	var z = int(coordinates[2])
	return (z < grid_z_len) and (z >= 0)

func load_materials():
	opaque_material = preload("res://Assets/Textures/Normal Material.tres")
	transparent_material = preload("res://Assets/Textures/Transparent Material.tres")

# updates voxels to be a sanitized, deep copy of new_voxel_data
func update_voxels(new_voxel_data):
	for x in range(0, grid_x_len):
		for y in range(0, grid_y_len):
			for z in range(0, grid_z_len):
				var index = calculate_voxel_index([x,y,z])
				set_voxel([x,y,z], new_voxel_data[index])

# In CubeGrid
func interact(other_object=null, info=null):
	# add a block!
	var global_point = info.position + (info.normal / 2)
	var local_point = to_local(global_point)
	var coords = [floor(local_point.x), floor(local_point.y), floor(local_point.z)]
	set_voxel(coords, Voxel.VoxelType.SAND)
