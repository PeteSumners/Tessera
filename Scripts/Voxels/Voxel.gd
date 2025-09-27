class_name Voxel

enum VoxelType {
	AIR,    # 0
	STONE,  # 1
	SAND,   # 2
	GLASS,  # 3
	DIRT,   # 4
	GRASS,  # 5
	GRAVEL  # 6
}

# Centralized voxel property definitions
const VOXEL_DATA = {
	VoxelType.AIR:   { "name": "AIR",   "transparent": true,  "solid": false, "light": 0 },
	VoxelType.STONE: { "name": "STONE", "transparent": false, "solid": true,  "light": 0 },
	VoxelType.SAND:  { "name": "SAND",  "transparent": false, "solid": true,  "light": 0 },
	VoxelType.GLASS: { "name": "GLASS", "transparent": true,  "solid": true,  "light": 0 },
	VoxelType.DIRT:  { "name": "DIRT",  "transparent": false, "solid": true,  "light": 0 },
	VoxelType.GRASS: { "name": "GRASS", "transparent": false, "solid": true,  "light": 0 },
	VoxelType.GRAVEL: { "name": "GRAVEL", "transparent": false, "solid": true,  "light": 0 }
}

static func get_voxel_name(id):
	if id in VOXEL_DATA:
		return VOXEL_DATA[id]["name"]
	return "NO NAME"

static func is_transparent(id):
	if id in VOXEL_DATA:
		return VOXEL_DATA[id]["transparent"]
	return true

static func is_solid(id):
	if id in VOXEL_DATA:
		return VOXEL_DATA[id]["solid"]
	return false

static func get_light_source_level(id):
	if id in VOXEL_DATA:
		return VOXEL_DATA[id]["light"]
	return 0
