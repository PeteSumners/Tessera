
extends CubeGrid
class_name Workshop
var debug_mesh: ImmediateMesh
var debug_material: StandardMaterial3D
var show_debug_triangles = false
var processed_tops = {}
var line_width = 0.1
var original_triangles = {
	"top": 0,
	"bottom": 0,
	"north": 0, 
	"south": 0,
	"east": 0,
	"west": 0,
}
var optimized_triangles = {
	"top": 0,
	"bottom": 0,
	"north": 0,
	"south": 0,
	"east": 0,
	"west": 0,
}
func _init():
	super()
	grid_x_len = 8
	grid_y_len = 8
	grid_z_len = 8
	debug_mesh = ImmediateMesh.new()
	debug_material = StandardMaterial3D.new()
	debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_material.vertex_color_use_as_albedo = true
	var debug_mesh_instance = MeshInstance3D.new()
	debug_mesh_instance.mesh = debug_mesh
	debug_mesh_instance.material_override = debug_material
	add_child(debug_mesh_instance)
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_BACKSPACE:
			show_debug_triangles = !show_debug_triangles
			grid_data_changed = true
		elif event.keycode == KEY_P:
			print_triangle_statistics()
func print_triangle_statistics():
	print("\nTriangle Statistics:")
	print("Direction  | Original | Optimized | Reduction %")
	print("-----------|----------|-----------|------------")
	for direction in original_triangles.keys():
		var orig = original_triangles[direction]
		var opt = optimized_triangles[direction]
		var reduction = 0.0 if orig == 0 else ((orig - opt) / float(orig) * 100.0)
		print("%9s | %8d | %9d | %9.1f%%" % [direction, orig, opt, reduction])
	print("\nTotal Triangles:")
	var total_orig = original_triangles.values().reduce(func(accum, number): return accum + number)
	var total_opt = optimized_triangles.values().reduce(func(accum, number): return accum + number)
	var total_reduction = 0.0 if total_orig == 0 else ((total_orig - total_opt) / float(total_orig) * 100.0)
	print("Original: %d" % total_orig)
	print("Optimized: %d" % total_opt)
	print("Reduction: %.1f%%" % total_reduction)
func draw_block_mesh(coordinates):
	var surface_tool_to_use = surface_tool
	var voxel = get_voxel(coordinates)
	if Voxel.is_transparent(voxel):
		surface_tool_to_use = transparent_surface_tool
	if voxel == 0:  
		return
	var verts = calculate_block_vertices(coordinates)
	var uvs = calculate_block_uvs(coordinates)
	var surrounding_coordinates = get_surrounding_coordinates(coordinates)
	var faces_data = [
		{
			"direction": [0, 1, 0],   
			"key": "top",             
			"surrounding_idx": 2,      
			"verts": [verts[2], verts[6], verts[7], verts[3]]  
		},
		{
			"direction": [0, -1, 0],   
			"key": "bottom",
			"surrounding_idx": 3,
			"verts": [verts[1], verts[5], verts[4], verts[0]]
		},
		{
			"direction": [1, 0, 0],    
			"key": "east",
			"surrounding_idx": 0,
			"verts": [verts[4], verts[5], verts[7], verts[6]]
		},
		{
			"direction": [-1, 0, 0],   
			"key": "west",
			"surrounding_idx": 1,
			"verts": [verts[1], verts[0], verts[2], verts[3]]
		},
		{
			"direction": [0, 0, 1],    
			"key": "north",
			"surrounding_idx": 4,
			"verts": [verts[5], verts[1], verts[3], verts[7]]
		},
		{
			"direction": [0, 0, -1],   
			"key": "south",
			"surrounding_idx": 5,
			"verts": [verts[0], verts[4], verts[6], verts[2]]
		}
	]
	for face in faces_data:
		var direction = face.direction
		var face_key = face.key
		var surrounding_idx = face.surrounding_idx
		var face_verts = face.verts
		var processed_key = str(coordinates) + "_" + face_key
		var other_coordinates = surrounding_coordinates[surrounding_idx]
		var other_voxel = get_voxel(other_coordinates)
		var other_voxel_transparent = Voxel.is_transparent(other_voxel)
		if other_voxel_transparent and (other_voxel != voxel):
			if direction[1] == 0:  
				original_triangles[face_key] += 2  
				optimized_triangles[face_key] += 2
				MeshHelper.draw_quad(
					surface_tool_to_use,
					face_verts,
					uvs,
					calculate_light_uvs(other_coordinates)
				)
			elif not processed_tops.has(processed_key):
				original_triangles[face_key] += 2
				var merged = find_merged_region(
					coordinates[0],
					coordinates[2],
					coordinates[1],
					direction
				)
				if merged.size() > 0:
					optimized_triangles[face_key] += 2
					var coord_y = merged.start_y
					for x in range(merged.start_x, merged.start_x + merged.width):
						for z in range(merged.start_z, merged.start_z + merged.depth):
							var key = str([x, coord_y, z]) + "_" + face_key
							processed_tops[key] = true
							if not (x == coordinates[0] and z == coordinates[2]):
								original_triangles[face_key] += 2
					draw_merged_region(merged, surface_tool_to_use, voxel)
				else:
					MeshHelper.draw_quad(
						surface_tool_to_use,
						face_verts,
						uvs,
						calculate_light_uvs(other_coordinates)
					)
func find_merged_region(start_x: int, start_z: int, start_y: int, direction: Array) -> Dictionary:
	var initial_type = get_voxel([start_x, start_y, start_z])
	if initial_type == Voxel.VoxelType.AIR:
		return {}
	var check_coordinates = [
		start_x + direction[0],
		start_y + direction[1],
		start_z + direction[2]
	]
	var check_voxel = get_voxel(check_coordinates)
	if not Voxel.is_transparent(check_voxel) or check_voxel == initial_type:
		return {}
	var width_axis = [1, 0, 0]  
	var depth_axis = [0, 0, 1]  
	if abs(direction[0]) > 0:
		width_axis = [0, 1, 0]  
		depth_axis = [0, 0, 1]  
	elif abs(direction[2]) > 0:
		width_axis = [1, 0, 0]  
		depth_axis = [0, 1, 0]  
	var width = 1
	var max_width = grid_x_len if width_axis[0] > 0 else grid_y_len
	for w in range(start_x + width_axis[0], max_width):
		var current_pos = [
			w if width_axis[0] > 0 else start_x,
			w if width_axis[1] > 0 else start_y,
			start_z
		]
		var check_pos = [
			current_pos[0] + direction[0],
			current_pos[1] + direction[1],
			current_pos[2] + direction[2]
		]
		var current_type = get_voxel(current_pos)
		var current_check = get_voxel(check_pos)
		if current_type != initial_type or not Voxel.is_transparent(current_check) or current_check == initial_type:
			break
		width += 1
	var depth = 1
	var can_expand = true
	var max_depth = grid_z_len if depth_axis[2] > 0 else grid_y_len
	while can_expand and (start_z + depth * depth_axis[2]) < max_depth:
		for w in range(width):
			var current_pos = [
				(start_x + w * width_axis[0]) if width_axis[0] > 0 else start_x,
				(start_y + w * width_axis[1]) if width_axis[1] > 0 else start_y,
				start_z + depth * depth_axis[2] if depth_axis[2] > 0 else start_z
			]
			var check_pos = [
				current_pos[0] + direction[0],
				current_pos[1] + direction[1],
				current_pos[2] + direction[2]
			]
			var current_type = get_voxel(current_pos)
			var current_check = get_voxel(check_pos)
			if current_type != initial_type or not Voxel.is_transparent(current_check) or current_check == initial_type:
				can_expand = false
				break
		if can_expand:
			depth += 1
	return {
		"start_x": start_x,
		"start_y": start_y,
		"start_z": start_z,
		"width": width,
		"depth": depth,
		"direction": direction,
		"voxel_type": initial_type
	}
func draw_merged_region(region: Dictionary, st: SurfaceTool, voxel_type: int):
	var direction = region.direction
	var y_offset = 0
	if direction[1] > 0:
		y_offset = 1
	elif direction[1] == 0:
		y_offset = 0.5
	var start_y = region.start_y + y_offset
	if show_debug_triangles:
		var points = []
		var color1
		var color2
		if direction[1] != 0:  
			points = [
				Vector3(region.start_x, start_y, region.start_z),
				Vector3(region.start_x + region.width, start_y, region.start_z),
				Vector3(region.start_x + region.width, start_y, region.start_z + region.depth),
				Vector3(region.start_x, start_y, region.start_z + region.depth)
			]
			color1 = Color(
				0.2 + (region.width / float(grid_x_len)) * 0.8,
				0.2 + (region.depth / float(grid_z_len)) * 0.8,
				0.5,
				1.0
			)
			color2 = Color(
				0.2 + (region.depth / float(grid_z_len)) * 0.8,
				0.2 + (region.width / float(grid_x_len)) * 0.8,
				0.7,
				1.0
			)
		else:  
			points = [
				Vector3(region.start_x, region.start_y, region.start_z),
				Vector3(region.start_x, region.start_y + 1, region.start_z),
				Vector3(region.start_x, region.start_y + 1, region.start_z + 1),
				Vector3(region.start_x, region.start_y, region.start_z + 1)
			]
			if direction[0] > 0:  
				points = points.map(func(p): return p + Vector3(1, 0, 0))
			elif direction[2] > 0:  
				points = points.map(func(p): 
					var rotated = p
					rotated.x = p.z
					rotated.z = -p.x
					return rotated + Vector3(0, 0, 1)
				)
			elif direction[2] < 0:  
				points = points.map(func(p):
					var rotated = p
					rotated.x = -p.z
					rotated.z = p.x
					return rotated
				)
			color1 = Color(0.8, 0.2, 0.2, 1.0)  
			color2 = Color(0.2, 0.8, 0.2, 1.0)  
		debug_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var reverse_winding = direction[1] < 0
		if not reverse_winding:
			for i in [0, 1, 2]:
				debug_mesh.surface_set_color(color1)
				debug_mesh.surface_add_vertex(points[i])
			for i in [0, 2, 3]:
				debug_mesh.surface_set_color(color2)
				debug_mesh.surface_add_vertex(points[i])
		else:
			for i in [0, 2, 1]:
				debug_mesh.surface_set_color(color1)
				debug_mesh.surface_add_vertex(points[i])
			for i in [0, 3, 2]:
				debug_mesh.surface_set_color(color2)
				debug_mesh.surface_add_vertex(points[i])
		debug_mesh.surface_end()
	else:
		var base_uvs = MeshHelper.calculate_tile_uvs(voxel_type, texture_sheet_width)
		for dx in range(region.width):
			for dz in range(region.depth):
				var block_points = [
					Vector3(region.start_x + dx, start_y, region.start_z + dz),
					Vector3(region.start_x + dx + 1, start_y, region.start_z + dz),
					Vector3(region.start_x + dx + 1, start_y, region.start_z + dz + 1),
					Vector3(region.start_x + dx, start_y, region.start_z + dz + 1)
				]
				if direction[1] < 0:
					block_points.reverse()
				MeshHelper.draw_quad(
					st,
					block_points,
					base_uvs,
					calculate_light_uvs([
						region.start_x + dx,
						region.start_y + (1 if direction[1] > 0 else -1),
						region.start_z + dz
					])
				)
func draw_outline_for_merged_region(start_x: float, y: float, start_z: float, width: float, depth: float, color: Color):
	var surface_tool_to_use = transparent_surface_tool
	surface_tool_to_use.set_color(color)
	draw_thick_line(
		Vector3(start_x, y, start_z),
		Vector3(start_x + width, y, start_z),
		surface_tool_to_use
	)
	draw_thick_line(
		Vector3(start_x, y, start_z + depth),
		Vector3(start_x + width, y, start_z + depth),
		surface_tool_to_use
	)
	draw_thick_line(
		Vector3(start_x, y, start_z),
		Vector3(start_x, y, start_z + depth),
		surface_tool_to_use
	)
	draw_thick_line(
		Vector3(start_x + width, y, start_z),
		Vector3(start_x + width, y, start_z + depth),
		surface_tool_to_use
	)
	surface_tool_to_use.set_color(Color(1, 1, 1))
func draw_thick_line(start: Vector3, end: Vector3, surface_tool: SurfaceTool):
	var direction = (end - start).normalized()
	var up = Vector3(0, 1, 0)
	var side = direction.cross(up).normalized() * line_width
	var v1 = start + side
	var v2 = start - side
	var v3 = end - side
	var v4 = end + side
	MeshHelper.draw_quad(surface_tool, [v1, v2, v3, v4])
	var height = Vector3(0, line_width, 0)
	var v5 = v1 + height
	var v6 = v2 + height
	var v7 = v3 + height
	var v8 = v4 + height
	MeshHelper.draw_quad(surface_tool, [v1, v5, v6, v2])
	MeshHelper.draw_quad(surface_tool, [v2, v6, v7, v3])
	MeshHelper.draw_quad(surface_tool, [v3, v7, v8, v4])
	MeshHelper.draw_quad(surface_tool, [v4, v8, v5, v1])
	MeshHelper.draw_quad(surface_tool, [v5, v8, v7, v6])
func generate_mesh_data():
	for direction in original_triangles.keys():
		original_triangles[direction] = 0
		optimized_triangles[direction] = 0
	processed_tops.clear()
	debug_mesh.clear_surfaces()
	generate_voxel_data()
	grid_data_changed = false
	for x in range(0, grid_x_len):
		for y in range(0, grid_y_len):
			for z in range(0, grid_z_len):
				draw_block_mesh([x,y,z])
	print_triangle_statistics()
func generate_voxel_data():
	clear_grid()
	build_floor()
	build_walls()
	build_ceiling()
func build_floor():
	for x in range(0, grid_x_len):
		for z in range(0, grid_z_len):
			set_voxel([x, 0, z], Voxel.VoxelType.STONE)
func build_walls():
	for y in range(0, grid_y_len):
		for x in range(0, grid_x_len):
			set_voxel([x, y, 0], Voxel.VoxelType.STONE)
			set_voxel([x, y, grid_z_len - 1], Voxel.VoxelType.STONE)
			if y > 2 and y < 6 and x % 2 == 0:
				set_voxel([x, y, 0], Voxel.VoxelType.GLASS)
				set_voxel([x, y, grid_z_len - 1], Voxel.VoxelType.GLASS)
		for z in range(0, grid_z_len):
			set_voxel([0, y, z], Voxel.VoxelType.STONE)
			set_voxel([grid_x_len - 1, y, z], Voxel.VoxelType.STONE)
			if y > 2 and y < 6 and z % 2 == 0:
				set_voxel([0, y, z], Voxel.VoxelType.GLASS)
				set_voxel([grid_x_len - 1, y, z], Voxel.VoxelType.GLASS)
func build_ceiling():
	for x in range(0, grid_x_len):
		for z in range(0, grid_z_len):
			if (x + z) % 4 == 0:
				set_voxel([x, grid_y_len - 1, z], Voxel.VoxelType.GLASS)
			else:
				set_voxel([x, grid_y_len - 1, z], Voxel.VoxelType.STONE)
