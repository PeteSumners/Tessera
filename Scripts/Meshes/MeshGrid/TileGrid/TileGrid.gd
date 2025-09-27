extends MeshGrid
class_name TileGrid

# returns tile vertices given x,y,z coordinates
static func calculate_tile_vertices(coordinates):
	return [
		Vector3(coordinates[0], coordinates[1], coordinates[2]),
		Vector3(coordinates[0]-1, coordinates[1], coordinates[2]),
		Vector3(coordinates[0]-1, coordinates[1]-1, coordinates[2]),
		Vector3(coordinates[0], coordinates[1]-1, coordinates[2])
	]

func add_collision_shapes():
	var center = [-grid_x_len*.5, -grid_y_len*.5, 0]
	var scale = Vector3(grid_x_len, grid_y_len, .1)
	add_collision_box(center, scale)
