extends Node3D
class_name VoxelWorld

# TODO: thread pool + add chunks based on position + procedural generation

var chunks = {}
const world_length = 2 # number of chunks on the x/z dimensions

# Called when the node enters the scene tree for the first time.
func _ready():
	#return # don't do anything with VoxelWorld right now. In fact, redo chunk generation code
	
	# initial chunks
	for chunk_x in range(0,world_length):
		for chunk_z in range(0,world_length):
			var chunk_coordinates = [chunk_x, chunk_z]
			#add_inactive_chunk(chunk_coordinates)
			activate_chunk(chunk_coordinates)
			#print("activate chunks later...")

# adds a chunk for the sake of data processing (not visiblity)
func add_inactive_chunk(chunk_coordinates):
	if (chunks.has(chunk_coordinates)): # don't add a chunk a second time!
		return
	var chunk = TerrainChunk.new(self, chunk_coordinates)
	chunks[chunk_coordinates] = chunk
	add_child(chunk)

func _process(_delta):
	# testing on-the-fly chunk creation
#	if (Time.get_ticks_msec() > 2000):
#		activate_chunk([0,0])
#	if (Time.get_ticks_msec() > 3000):
#		activate_chunk([0,1])
#	if (Time.get_ticks_msec() > 4000):
#		activate_chunk([0,2])
#	if (Time.get_ticks_msec() > 5000):
#		activate_chunk([1,2])
	pass

# makes sure a chunk is in the world, and then makes it active
func activate_chunk(chunk_coordinates):
	if (not chunks.has(chunk_coordinates)):
		add_inactive_chunk(chunk_coordinates)
	var chunk = chunks[chunk_coordinates]
	chunk.activate()

# return the ID of the voxel at global coordinates (x,y,z) 
func get_voxel(coordinates):
	var chunk_and_local_coordinates = get_chunk_and_local_coordinates(coordinates)
	if chunk_and_local_coordinates == null:
		return -1 # return invalid voxel if no chunk
	else:
		return chunk_and_local_coordinates[0].get_voxel(chunk_and_local_coordinates[1])

# returns the light level at the given coordinates
func get_light_level(coordinates):
	var chunk_and_local_coordinates = get_chunk_and_local_coordinates(coordinates)
	if chunk_and_local_coordinates == null:
		if (coordinates[1] < 0): return 0 # no light if below world
		else: return CubeGrid.ambient_light_level # return default (ambient) light level if coordinates are otherwise invalid (above world)
	else: # coordinates are within this world (and thus one of its chunks)
		return chunk_and_local_coordinates[0].get_light_level(chunk_and_local_coordinates[1]) # return light level from within a chunk

func flood_fill_light(coordinates, light_level):
	var chunk_and_local_coordinates = get_chunk_and_local_coordinates(coordinates)
	if chunk_and_local_coordinates == null:
		return #  no chunk. only happens with invalid y coordinates
	else:
		chunk_and_local_coordinates[0].flood_fill_light(chunk_and_local_coordinates[1], light_level)

# returns the chunk and local coordinates associated with the given global coordinates in an array
func get_chunk_and_local_coordinates(coordinates):
	var y = coordinates[1]
	if ((y < 0) or (y >= TerrainChunk.chunk_height)): return null # no chunk if out of y bounds
	var chunk_coordinates = get_chunk_coordinates(coordinates)
	if not chunks.has(chunk_coordinates): 
		add_inactive_chunk(chunk_coordinates)
	var chunk = chunks[chunk_coordinates]
	return [chunk, to_local_voxel_coordinates(coordinates, chunk_coordinates)]

# returns local coordinates of a voxel in a chunk given the voxel's global coordinates
# passing chunk_coordinates to this method for a marginal performance boost (don't have to call get_chunk_coordinates(coordinates) multiple times)
static func to_local_voxel_coordinates(voxel_coordinates, chunk_coordinates):
	var local_x = voxel_coordinates[0] - (chunk_coordinates[0] * TerrainChunk.chunk_width)
	var local_y = voxel_coordinates[1]
	var local_z = voxel_coordinates[2] - (chunk_coordinates[1] * TerrainChunk.chunk_width)
	return [local_x, local_y, local_z]

# return chunk coordinates of a voxel given the voxel's global (x,y,z) coordinates
static func get_chunk_coordinates(voxel_coordinates):
	var chunk_x = voxel_coordinates[0]
	var chunk_z = voxel_coordinates[2]
	
	# handle the case of negative chunk coordinates
	if (chunk_x < 0): chunk_x -= (TerrainChunk.chunk_width - 1)
	if (chunk_z < 0): chunk_z -= (TerrainChunk.chunk_width - 1)
	
	chunk_x /= TerrainChunk.chunk_width
	chunk_z /= TerrainChunk.chunk_width
	
	return [chunk_x, chunk_z]
