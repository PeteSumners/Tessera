# TODO: multithread light data updates
# You'll need to make a really efficient light/mesh update system, though (only update the blocks around the ones whose light level changed)
# TODO: refactor flood_fill_light code
# TODO: refactor terrain chunk initialization code vs. terrain chunk creation code in VoxelWorld.gd

extends CubeGrid
class_name TerrainChunk

var world # voxel chunks always have the voxel world as their parent
var chunk_coordinates # chunk's coordinates in the world

const chunk_width = 8
const chunk_height = 8

# called during constructor
func _init(_world, _chunk_coordinates): # TerrainChunks must ALWAYS have a world and associated chunk_coordinates in that world
	world = _world
	chunk_coordinates = _chunk_coordinates
	grid_x_len = chunk_width
	grid_y_len = chunk_height
	grid_z_len = chunk_width
	deactivate() # terrain chunks shouldn't start as active
	super()

func _ready():
	global_position = Vector3(chunk_coordinates[0] * grid_x_len, 0, chunk_coordinates[1] * grid_z_len)

func generate_voxel_data():
	generate_test_data()


func generate_light_data():
	reset_light_data()
	
	# Handle skylight first - from top to bottom
	for reverse_y in range(0, grid_y_len): 
		var y = (grid_y_len - 1) - reverse_y
		for x in range(0, grid_x_len):
			for z in range(0, grid_z_len):
				var coordinates = [x,y,z]
				var top_coordinates = [x,y+1,z]
				
				# Get skylight status
				var sky_light = false
				var top_sky_light = false
				
				top_sky_light = get_ambient_light(top_coordinates)
				
				# If block is transparent and has skylight above, it gets skylight
				if Voxel.is_transparent(get_voxel(coordinates)) and top_sky_light:
					sky_light = true
					
				set_ambient_light(coordinates, sky_light)
				if sky_light:
					set_light_level(coordinates, ambient_light_level)
	
	# Then do standard lighting from emitters and ambient sources
	for x in range(0, grid_x_len):
		for y in range(0, grid_y_len):
			for z in range(0, grid_z_len):
				var coordinates = [x,y,z]
				var voxel = get_voxel(coordinates)
				var light_level = max(
					get_light_level(coordinates),
					Voxel.get_light_source_level(voxel)
				)
				flood_fill_light(coordinates, light_level)

# generate some test voxel data
func generate_test_data():
	for x in range(0, grid_x_len):
		for y in range(0, grid_y_len):
			for z in range(0, grid_z_len):
#				var voxel_id = 2 # TODO: proper terrain generation
#
#				if (y <= 4) and y != 0: voxel_id = 0 # low layer
#
#				# glass exhibition
#				if (y == 7 or y == 8) and \
#					(x != 0 and x != grid_x_len-1 and z != 0 and z != grid_z_len-1): voxel_id = 3
#				if ((x >= 2 and x <= 10) and (y >= 7 and y <= 8) and ((z >= 4) and (z <= 6))):
#					voxel_id = 3
#					if (x == 6): voxel_id = 0
#
#				# make some tunnels
#				if (y == 7 or y == 8) and (x == 3): voxel_id = 0
#				if (x == 4 and z == 5 and y > 0): voxel_id = 0
				
				# allow chunk sides to be seen
				#if x == 0: voxel_id = 0
				
				var fast_noise_lite = FastNoiseLite.new() # smooth_simplex noise by default
				var rng = RandomNumberGenerator.new()
				rng.randomize()
				fast_noise_lite.seed = rng.randi()
				var noise_value = fast_noise_lite.get_noise_3d(x,y,z)
				var voxel_type = Voxel.VoxelType.AIR
				if noise_value > 0: voxel_type = Voxel.VoxelType.SAND
				set_voxel([x,y,z],voxel_type)

# TODO: refactor voxel indexing code in get_voxel() and get_light_level()
# gets the voxel in world given local (relative to this chunk) voxel coordinates (x,y,z)
func get_voxel(coordinates):
	if (coordinates_within_bounds(coordinates)):
		return super.get_voxel(coordinates) # normal get_voxel if within bounds
	else: return world.get_voxel(calculate_global_coordinates(coordinates)) # go to the whole world if out of x/z bounds

# gets the light level in world given local (relative to this chunk) voxel coordinates (x,y,z)
# overrides CubeGrid.get_light_level()!
func get_light_level(coordinates):
	if (coordinates_within_bounds(coordinates)):
		return super.get_light_level(coordinates) # normal get_light_level if within bounds
	else:
		return world.get_light_level(calculate_global_coordinates(coordinates)) # go to the whole world if out of bounds

func flood_fill_light(coordinates, light_level):
	if (coordinates_within_bounds(coordinates)): # only flood fill light if coordinates are within this TerrainChunk's bounds
		super.flood_fill_light(coordinates, light_level)
	elif is_grid_active: # only flood fill light to other chunks if this one is active
		world.flood_fill_light(calculate_global_coordinates(coordinates), light_level)

# return global version of the local (relative to this chunk) voxel coordinates (x,y,z)
func calculate_global_coordinates(coordinates):
	var global_x = coordinates[0] + (chunk_coordinates[0] * grid_x_len)
	var global_y = coordinates[1]
	var global_z = coordinates[2] + (chunk_coordinates[1] * grid_z_len)
	return [global_x, global_y, global_z]
