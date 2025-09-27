extends CubeGrid
class_name GreedyCubeGrid
var merge_masks = {
	"XP": [], 
	"XN": [], 
	"YP": [], 
	"YN": [], 
	"ZP": [], 
	"ZN": []  
}
var greedy_surface_tool = null
const DIRECTION_SUFFIXES = {
	"XP": "_xp",
	"XN": "_xn", 
	"YP": "_yp",
	"YN": "_yn",
	"ZP": "_zp",
	"ZN": "_zn"
}
const DIRECTION_NORMALS = {
	"XP": [1, 0, 0],
	"XN": [-1, 0, 0],
	"YP": [0, 1, 0],
	"YN": [0, -1, 0],
	"ZP": [0, 0, 1],
	"ZN": [0, 0, -1]
}
const DIRECTION_TO_INDEX = {
	"XP": 0,
	"XN": 1,
	"YP": 2,
	"YN": 3,
	"ZP": 4,
	"ZN": 5
}
var vertex_count = 0
var triangle_count = 0

# Override generate_voxel_data to create a test pattern
func generate_diagonal_pattern():
	clear_grid()
	
	# Create some test blocks to demonstrate column merging
	for x in range(grid_x_len):
		for z in range(grid_z_len):
			# Create a base layer
			set_voxel([x, 0, z], Voxel.VoxelType.STONE)
			
			# Add some glass columns
			if (x + z) % 2 == 0:
				for y in range(1, 3):
					set_voxel([x, y, z], Voxel.VoxelType.GLASS)
			
			# Add some sand pillars
			if (x + z) % 3 == 0:
				for y in range(1, 4):
					set_voxel([x, y, z], Voxel.VoxelType.SAND)

func _init():
	super()
	# Make the grid a bit larger to better demonstrate the effect
	grid_x_len = 10
	grid_y_len = 10
	grid_z_len = 10
	reset_mesh_stats()
	initialize_greedy_surface_tool()

func initialize_greedy_surface_tool():
	greedy_surface_tool = MeshHelper.get_new_surface_tool()

func _ready():
	super()

func reset_mesh_stats():
	vertex_count = 0
	triangle_count = 0

func try_merge_face(start_x: int, start_y: int, start_z: int, direction: String, normal: Array):
	var current_idx = calculate_voxel_index([start_x, start_y, start_z])
	if merge_masks[direction][current_idx]:
		return
		
	var voxel_type = get_voxel([start_x, start_y, start_z])
	if voxel_type == Voxel.VoxelType.AIR:
		return
		
	var y_extent = 1
	var z_extent = 1
	var x_extent = 1
	
	if abs(normal[0]) > 0:  # X-axis faces
		while start_y + y_extent < grid_y_len:
			var test_pos = [start_x, start_y + y_extent, start_z]
			if get_voxel(test_pos) != voxel_type or not is_face_visible(test_pos, normal):
				break
			y_extent += 1
			
		var can_expand_z = true
		while start_z + z_extent < grid_z_len and can_expand_z:
			for y in range(start_y, start_y + y_extent):
				var test_pos = [start_x, y, start_z + z_extent]
				if get_voxel(test_pos) != voxel_type or not is_face_visible(test_pos, normal):
					can_expand_z = false
					break
			if can_expand_z:
				z_extent += 1
				
	elif abs(normal[1]) > 0:  # Y-axis faces
		while start_x + x_extent < grid_x_len:
			var test_pos = [start_x + x_extent, start_y, start_z]
			if get_voxel(test_pos) != voxel_type or not is_face_visible(test_pos, normal):
				break
			x_extent += 1
			
		var can_expand_z = true
		while start_z + z_extent < grid_z_len and can_expand_z:
			for x in range(start_x, start_x + x_extent):
				var test_pos = [x, start_y, start_z + z_extent]
				if get_voxel(test_pos) != voxel_type or not is_face_visible(test_pos, normal):
					can_expand_z = false
					break
			if can_expand_z:
				z_extent += 1
				
	else:  # Z-axis faces
		while start_x + x_extent < grid_x_len:
			var test_pos = [start_x + x_extent, start_y, start_z]
			if get_voxel(test_pos) != voxel_type or not is_face_visible(test_pos, normal):
				break
			x_extent += 1
			
		var can_expand_y = true
		while start_y + y_extent < grid_y_len and can_expand_y:
			for x in range(start_x, start_x + x_extent):
				var test_pos = [x, start_y + y_extent, start_z]
				if get_voxel(test_pos) != voxel_type or not is_face_visible(test_pos, normal):
					can_expand_y = false
					break
			if can_expand_y:
				y_extent += 1

	# Mark merged faces
	if abs(normal[0]) > 0:  # X-axis faces
		for y in range(start_y, start_y + y_extent):
			for z in range(start_z, start_z + z_extent):
				var idx = calculate_voxel_index([start_x, y, z])
				merge_masks[direction][idx] = true
				
	elif abs(normal[1]) > 0:  # Y-axis faces
		for x in range(start_x, start_x + x_extent):
			for z in range(start_z, start_z + z_extent):
				var idx = calculate_voxel_index([x, start_y, z])
				merge_masks[direction][idx] = true
				
	else:  # Z-axis faces
		for x in range(start_x, start_x + x_extent):
			for y in range(start_y, start_y + y_extent):
				var idx = calculate_voxel_index([x, y, start_z])
				merge_masks[direction][idx] = true

	# Generate merged vertices based on direction
	var merged_verts
	if abs(normal[0]) > 0:
		merged_verts = generate_face_vertices(start_x, start_y, start_z, y_extent, z_extent, normal)
	elif abs(normal[1]) > 0:
		merged_verts = generate_face_vertices(start_x, start_y, start_z, x_extent, z_extent, normal)
	else:
		merged_verts = generate_face_vertices(start_x, start_y, start_z, x_extent, y_extent, normal)
		
	draw_merged_face(merged_verts, voxel_type, [start_x, start_y, start_z], direction)

# Override to use material-specific surface tools
func draw_merged_face(verts: Array, voxel_type: int, start_pos: Array, direction: String):
	var dimensions = calculate_face_dimensions(verts)
	var primary_extent = dimensions.x
	var secondary_extent = dimensions.y
	var normal = DIRECTION_NORMALS[direction]
	
	# Use GreedyCubeGrid's UV calculation
	var uvs = MeshHelper.calculate_face_uvs(normal, primary_extent, secondary_extent)
	
	var light_pos = [
		start_pos[0] + normal[0],
		start_pos[1] + normal[1],
		start_pos[2] + normal[2]
	]
	var light_uvs = calculate_light_uvs(light_pos)
	
	# Use material-specific surface tool
	var dir_index = DIRECTION_TO_INDEX[direction]
	var surface_tool = SurfaceToolManager.get_surface_tool(voxel_type, dir_index)
	MeshHelper.draw_quad(surface_tool, verts, uvs, light_uvs)
	vertex_count += 4
	triangle_count += 2

func calculate_face_dimensions(verts: Array) -> Vector2:
	if len(verts) < 4:
		return Vector2.ZERO
	var primary_extent = (verts[1] - verts[0]).length()
	var secondary_extent = (verts[2] - verts[1]).length()
	return Vector2(primary_extent, secondary_extent)

func generate_face_vertices(start_x: int, start_y: int, start_z: int, primary_extent: float, secondary_extent: float, normal: Array) -> Array:
	if normal[0] > 0:  
		return [
			Vector3(start_x + 1, start_y + primary_extent, start_z),                    
			Vector3(start_x + 1, start_y, start_z),                                     
			Vector3(start_x + 1, start_y, start_z + secondary_extent),                  
			Vector3(start_x + 1, start_y + primary_extent, start_z + secondary_extent)  
		]
	elif normal[0] < 0:  
		return [
			Vector3(start_x, start_y, start_z),                                     
			Vector3(start_x, start_y + primary_extent, start_z),                    
			Vector3(start_x, start_y + primary_extent, start_z + secondary_extent), 
			Vector3(start_x, start_y, start_z + secondary_extent)                   
		]
	elif normal[1] > 0:  
		return [
			Vector3(start_x, start_y + 1, start_z),                                     
			Vector3(start_x + primary_extent, start_y + 1, start_z),                    
			Vector3(start_x + primary_extent, start_y + 1, start_z + secondary_extent), 
			Vector3(start_x, start_y + 1, start_z + secondary_extent)                   
		]
	elif normal[1] < 0:  
		return [
			Vector3(start_x + primary_extent, start_y, start_z),                    
			Vector3(start_x, start_y, start_z),                                     
			Vector3(start_x, start_y, start_z + secondary_extent),                  
			Vector3(start_x + primary_extent, start_y, start_z + secondary_extent)  
		]
	elif normal[2] > 0:  
		return [
			Vector3(start_x + primary_extent, start_y, start_z + 1),                    
			Vector3(start_x, start_y, start_z + 1),                                     
			Vector3(start_x, start_y + secondary_extent, start_z + 1),                  
			Vector3(start_x + primary_extent, start_y + secondary_extent, start_z + 1)  
		]
	else:  
		return [
			Vector3(start_x, start_y, start_z),                                     
			Vector3(start_x + primary_extent, start_y, start_z),                    
			Vector3(start_x + primary_extent, start_y + secondary_extent, start_z), 
			Vector3(start_x, start_y + secondary_extent, start_z)                   
		]


func generate_mesh_data():
	generate_light_data()
	grid_data_changed = false
	reset_mesh_stats()
	for direction in merge_masks:
		var size = grid_x_len * grid_y_len * grid_z_len
		merge_masks[direction] = []
		merge_masks[direction].resize(size)
		merge_masks[direction].fill(false)
	for direction in DIRECTION_NORMALS:
		generate_faces(direction, DIRECTION_NORMALS[direction])


func finalize_meshes():
	for voxel_type in Voxel.VoxelType.values():
		if voxel_type == Voxel.VoxelType.AIR:
			continue
		for dir_index in range(SurfaceToolManager.NUM_DIRECTIONS):
			var surface_tool = SurfaceToolManager.get_surface_tool(voxel_type, dir_index)
			var material = SurfaceToolManager.get_material(voxel_type, dir_index)
			var mesh_instance = MeshHelper.finish_mesh(surface_tool, material)
			add_child(mesh_instance)
	SurfaceToolManager.reset_surface_tools()
	add_collision_shapes()

func add_collision_shapes():
	# Process each column in the grid
	for x in range(grid_x_len):
		for z in range(grid_z_len):
			process_column(x, z)

func process_column(x: int, z: int):
	var current_start = -1
	var current_type = -1
	
	# Scan vertically through the column
	for y in range(grid_y_len):
		var voxel = get_voxel([x, y, z])
		
		# Start new collision shape if we hit a solid block
		if current_start == -1 and Voxel.is_solid(voxel):
			current_start = y
			current_type = voxel
			continue
			
		# End current collision shape if we hit air or different block type
		if current_start != -1:
			if !Voxel.is_solid(voxel) or voxel != current_type:
				add_column_collision(x, z, current_start, y)
				current_start = -1
				
				# Start new shape immediately if we hit a different solid block
				if Voxel.is_solid(voxel):
					current_start = y
					current_type = voxel
	
	# Add final collision shape if column ended with solid blocks
	if current_start != -1:
		add_column_collision(x, z, current_start, grid_y_len)

func add_column_collision(x: int, z: int, start_y: int, end_y: int):
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	
	# Use full-size collision shapes since they're part of the same body
	box_shape.size = Vector3(1.0, end_y - start_y, 1.0)
	collision_shape.shape = box_shape
	
	# Position collision shape at center of column section
	collision_shape.position = Vector3(
		x + 0.5,  # Center of block in X
		start_y + (end_y - start_y) * 0.5,  # Middle of vertical section
		z + 0.5   # Center of block in Z
	)
	
	add_child(collision_shape)

func generate_faces(direction: String, normal: Array):
	for x in range(0, grid_x_len):
		for y in range(0, grid_y_len):
			for z in range(0, grid_z_len):
				var idx = calculate_voxel_index([x, y, z])
				if not merge_masks[direction][idx] and is_face_visible([x, y, z], normal):
					try_merge_face(x, y, z, direction, normal)

func is_face_visible(pos: Array, normal: Array) -> bool:
	var voxel = get_voxel(pos)
	if voxel == Voxel.VoxelType.AIR:
		return false
	var neighbor_pos = [
		pos[0] + normal[0],
		pos[1] + normal[1],
		pos[2] + normal[2]
	]
	if not coordinates_within_bounds(neighbor_pos):
		return true
	var neighbor_voxel = get_voxel(neighbor_pos)
	return (voxel != neighbor_voxel) and (
		Voxel.is_transparent(neighbor_voxel) or
		Voxel.is_transparent(voxel)
	)

func generate_voxel_data():
	super()
	return
	
	clear_grid()
	print("Generating voxel data with dimensions: ", grid_x_len, ", ", grid_y_len, ", ", grid_z_len)
	
	for x in range(0, grid_x_len):
		for y in range(0, grid_y_len):
			for z in range(0, grid_z_len):
				var voxel_type = Voxel.VoxelType.AIR
				if x == 1 and z == 0: 
					voxel_type = Voxel.VoxelType.STONE
				elif y == 1 and z == 0:
					voxel_type = Voxel.VoxelType.SAND
				elif z == 1:
					voxel_type = Voxel.VoxelType.GLASS
				print("Setting voxel at [%d,%d,%d] to type: %d" % [x,y,z,voxel_type])
				set_voxel([x, y, z], voxel_type)
