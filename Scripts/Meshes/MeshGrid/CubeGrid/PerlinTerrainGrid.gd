extends GreedyCubeGrid
class_name PerlinTerrainGrid

var perlin_noise := FastNoiseLite.new()
var height_noise := FastNoiseLite.new()
var material_noise := FastNoiseLite.new()

func _init():
	super()
	# Configure primary noise for terrain height
	perlin_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	perlin_noise.seed = randi()
	perlin_noise.frequency = 0.02  # Lower frequency for smoother, broader terrain
	perlin_noise.fractal_octaves = 5
	perlin_noise.fractal_gain = 0.6
	perlin_noise.fractal_lacunarity = 2.0

	# Secondary noise for biome-like variation
	height_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	height_noise.seed = randi() + 1  # Different seed for variation
	height_noise.frequency = 0.05
	height_noise.fractal_octaves = 3
	height_noise.fractal_gain = 0.4

	# Tertiary noise for material blobs
	material_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	material_noise.seed = randi() + 2
	material_noise.frequency = 0.1  # Adjust for blob size: lower for larger blobs
	material_noise.fractal_octaves = 2
	material_noise.fractal_gain = 0.5

func generate_voxel_data():
	clear_grid()

	# Define terrain parameters
	var max_height = grid_y_len * 0.7  # Max height is 70% of grid height
	var base_height = grid_y_len * 0.2  # Base ground level
	var water_level = base_height + 2.0  # Water level for the sand biome

	var half_x = grid_x_len / 2
	var half_z = grid_z_len / 2

	for x in range(grid_x_len):
		for z in range(grid_z_len):
			# Determine biome based on quarters
			var biome_id = 0
			if x < half_x:
				if z < half_z:
					biome_id = 0  # Sand with glass for water
				else:
					biome_id = 1  # Grass
			else:
				if z < half_z:
					biome_id = 2  # Stone/gravel
				else:
					biome_id = 3  # Stone/dirt

			# Get 2D noise for terrain height (less influence for more hard-coded feel)
			var world_x = x
			var world_z = z
			var height_noise_value = perlin_noise.get_noise_2d(world_x, world_z)
			# Reduce noise impact for more deterministic heights
			var terrain_height = base_height + (height_noise_value + 1.0) * 0.5 * (max_height * 0.5)  # Halved noise amplitude
			terrain_height = clamp(terrain_height, base_height, grid_y_len - 1)

			# Secondary noise for variation (reduced influence)
			var biome_noise = height_noise.get_noise_2d(world_x, world_z) * 0.5  # Halved amplitude

			# Material noise for blob distribution
			var mat_noise = material_noise.get_noise_2d(world_x, world_z)

			# Calculate effective height for water in sand biome
			var effective_height = terrain_height
			if biome_id == 0:
				effective_height = max(terrain_height, water_level)

			# Fill column
			for y in range(grid_y_len):
				if y > effective_height:
					continue

				var height_ratio = float(y) / terrain_height if terrain_height > 0 else 0.0

				var voxel_type = Voxel.VoxelType.DIRT  # Default

				if biome_id == 0:  # Sand with glass water
					if y > terrain_height:
						voxel_type = Voxel.VoxelType.GLASS
					else:
						voxel_type = Voxel.VoxelType.SAND
					# Blob-like exposed sand and glass at top
					if y == floor(terrain_height):
						voxel_type = Voxel.VoxelType.SAND if mat_noise > 0 else Voxel.VoxelType.GLASS
					if y == floor(effective_height):
						voxel_type = Voxel.VoxelType.GLASS if mat_noise > 0 else Voxel.VoxelType.SAND
				elif biome_id == 1:  # Grass
					if height_ratio > 0.8:
						voxel_type = Voxel.VoxelType.GRASS
					else:
						voxel_type = Voxel.VoxelType.DIRT
					# Blob-like grass and dirt at top
					if y == floor(terrain_height):
						voxel_type = Voxel.VoxelType.GRASS if mat_noise > 0 else Voxel.VoxelType.DIRT
				elif biome_id == 2:  # Stone/gravel
					voxel_type = Voxel.VoxelType.GRAVEL if biome_noise > 0.0 else Voxel.VoxelType.STONE
					# Blob-like stone and gravel at top
					if y == floor(terrain_height):
						voxel_type = Voxel.VoxelType.STONE if mat_noise > 0 else Voxel.VoxelType.GRAVEL
				elif biome_id == 3:  # Stone/dirt
					voxel_type = Voxel.VoxelType.DIRT if biome_noise > 0.0 else Voxel.VoxelType.STONE
					# Blob-like stone and dirt at top
					if y == floor(terrain_height):
						voxel_type = Voxel.VoxelType.STONE if mat_noise > 0 else Voxel.VoxelType.DIRT

				set_voxel([x, y, z], voxel_type)

	# Add isolated floating grass block in center sky
	var center_x = floor(grid_x_len / 2.0)
	var center_z = floor(grid_z_len / 2.0)
	var sky_y = grid_y_len - 5  # High up, adjust as needed
	set_voxel([center_x, sky_y, center_z], Voxel.VoxelType.GRASS)
