class_name MeshHelper

static func get_new_surface_tool():
	var st = SurfaceTool.new()
	reset_surface_tool(st)
	return st

static func reset_surface_tool(st):
	st.clear()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

static func draw_quad(surface_tool, verts, uvs=null, uv2s=null):
	var indices = [0,1,2,0,2,3]
	if uvs == null: 
		uvs = quad_placeholder_uvs()
	if uv2s == null: 
		uv2s = quad_placeholder_uvs()
	
	for i in indices:
		surface_tool.set_uv(uvs[i])
		surface_tool.set_uv2(uv2s[i])
		surface_tool.add_vertex(verts[i])

static func quad_placeholder_uvs():
	return [
		Vector2.ZERO,
		Vector2.ZERO,
		Vector2.ZERO,
		Vector2.ZERO
	]

static func finish_mesh(surface_tool, material=null):
	surface_tool.index()
	surface_tool.generate_normals()
	var array_mesh = surface_tool.commit()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	if (material != null):
		mesh_instance.material_override = material
	return mesh_instance

static func calculate_tile_uvs(tile_index, tile_sheet_width):
	var tile_width = 1.0 / tile_sheet_width
	var start_x = tile_index % tile_sheet_width
	var start_y = tile_index / tile_sheet_width
	return [
		tile_width * Vector2(start_x, start_y),
		tile_width * Vector2(start_x+1, start_y),
		tile_width * Vector2(start_x+1, start_y+1),
		tile_width * Vector2(start_x, start_y+1)
	]

static func calculate_face_uvs(normal: Array, primary_extent: float, secondary_extent: float) -> Array:
	var uv_xp = [
		Vector2(secondary_extent, 0),
		Vector2(secondary_extent, primary_extent),
		Vector2(0, primary_extent),
		Vector2(0, 0)
	]
	var uv_xn = [
		Vector2(0, primary_extent),
		Vector2(0, 0),
		Vector2(secondary_extent, 0),
		Vector2(secondary_extent, primary_extent)
	]
	var uv_yp = [
		Vector2(0, 0),
		Vector2(primary_extent, 0),
		Vector2(primary_extent, secondary_extent),
		Vector2(0, secondary_extent)
	]
	var uv_yn = [
		Vector2(primary_extent, secondary_extent),
		Vector2(0, secondary_extent),
		Vector2(0, 0),
		Vector2(primary_extent, 0)
	]
	var uv_zp = [
		Vector2(0, secondary_extent),
		Vector2(primary_extent, secondary_extent),
		Vector2(primary_extent, 0),
		Vector2(0, 0)
	]
	var uv_zn = [
		Vector2(primary_extent, secondary_extent),
		Vector2(0, secondary_extent),
		Vector2(0, 0),
		Vector2(primary_extent, 0)
	]
	
	if normal[0] > 0:
		return uv_xp
	elif normal[0] < 0:
		return uv_xn
	elif normal[1] > 0:
		return uv_yp
	elif normal[1] < 0:
		return uv_yn
	elif normal[2] > 0:
		return uv_zp
	else:
		return uv_zn

static func standard_face_uvs(normal: Array) -> Array:
	return calculate_face_uvs(normal, 1.0, 1.0)
