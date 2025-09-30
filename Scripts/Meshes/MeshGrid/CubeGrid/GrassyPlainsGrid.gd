extends GreedyCubeGrid
class_name GrassyPlainsGrid

var terrain_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()

func _init():
	super()
	# Set grid dimensions
	grid_x_len = 64
	grid_y_len = 16
	grid_z_len = 64
	
	# Primary noise for gentle rolling hills
	terrain_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	terrain_noise.seed = randi()
	terrain_noise.frequency = 0.008  # Very low frequency for wide, flat hills
	terrain_noise.fractal_octaves = 2  # Fewer octaves for smoother, flatter terrain
	terrain_noise.fractal_gain = 0.4
	terrain_noise.fractal_lacunarity = 2.0

	# Detail noise for subtle surface variation
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	detail_noise.seed = randi() + 1
	detail_noise.frequency = 0.05  # Lower frequency for wider bumps
	detail_noise.fractal_octaves = 2
	detail_noise.fractal_gain = 0.25

func generate_voxel_data():
	clear_grid()

	# Terrain parameters for gentle plains
	var base_height = grid_y_len * 0.4  # Middle of the world
	var wave_amplitude = 5.0  # Reduced height variation for flatter terrain
	var detail_amplitude = 1.0  # Smaller surface bumps

	for x in range(grid_x_len):
		for z in range(grid_z_len):
			# Get noise values once per column
			var terrain_value = terrain_noise.get_noise_2d(x, z)
			var detail_value = detail_noise.get_noise_2d(x, z)
			
			# Calculate height with gentle waves
			var height = base_height + (terrain_value * wave_amplitude) + (detail_value * detail_amplitude)
			var height_int = int(clamp(height, 0, grid_y_len - 1))
			
			# Fill column with minimal calculations
			for y in range(height_int + 1):
				# Top 2 layers are grass, everything below is dirt
				var voxel_type = Voxel.VoxelType.GRASS if y >= height_int - 1 else Voxel.VoxelType.DIRT
				set_voxel([x, y, z], voxel_type)
