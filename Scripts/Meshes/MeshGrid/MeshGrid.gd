# implements a bunch of common methods/data structures used by various kinds of mesh grids
# TODO: network grid_<?>_len values so that you aren't just relying on default x,y,z length values (what happens if x/y/z length changes on one machine and not the other?)
# TODO: small updates and large updates for reliable packets (don't just send ALL the data if only a little data (a character/voxel/whatever) changes

extends PhysicsObject
class_name MeshGrid

var surface_tool = null # opaque surface tool
var opaque_material = null # material associated with surface_tool
var opaque_mesh_instance = null # current opaque MeshInstance

var transparent_surface_tool = null # separate opaque/transparent meshes to avoid rendering glitches
var transparent_material = null # material associated with transparent_surface_tool
var transparent_mesh_instance = null # current transparent MeshInstance

var grid_data_changed = false # whether grid data has changed since the last mesh update
@export var is_grid_active = true # whether this MeshGrid should update light/mesh data of its own volition. default to active behavior
var updating_mesh = false # whether the mesh is currently being updated (in a separate thread)
var new_mesh_instance_available = false # whether a new MeshInstance has been made ready to be added to the scene tree

var grid_x_len = 16
var grid_y_len = 16

var mesh_nodes_to_delete = [] # nodes to delete on mesh resets

func _init():
	load_materials()
	initialize_surface_tools()

# called once in scene tree
func _process(_delta):
	if (is_grid_active and grid_data_changed and (not updating_mesh)):
		queue_mesh_update()
	if new_mesh_instance_available:
		update_mesh_instances()

func queue_mesh_update():
	updating_mesh = true
	#ThreadPool.queue_task([self, "thread_update_mesh"])
	thread_update_mesh(self)

# update chunk visuals (light_data, uvs, mesh, etc)
func thread_update_mesh(userdata):
	grid_data_changed = false # right before generating mesh data, in case grid data changes again and another mesh needs to be generated
	generate_mesh_data()
	finalize_meshes()
	#ThreadPool.queue_task_finished(userdata) # free up the thread

func generate_mesh_data():
	pass # should be overridden by child classes

func activate():
	is_grid_active = true

func deactivate():
	is_grid_active = false

# create new MeshInstances from surface tools
func finalize_meshes():
	if (surface_tool != null): opaque_mesh_instance = finalize_surface_tool(surface_tool, opaque_material)
	if (transparent_surface_tool != null): transparent_mesh_instance = finalize_surface_tool(transparent_surface_tool, transparent_material)
	new_mesh_instance_available = true

# creates a mesh with the given surface tool, and then resets the surface tool
# returns a MeshInstance with the new mesh
func finalize_surface_tool(st, material):
	var mesh_instance = MeshHelper.finish_mesh(st, material)
	MeshHelper.reset_surface_tool(st) # prepare the SurfaceTool for future use
	return mesh_instance

# replace old mesh instances with new ones (this is where get_children and add_child calls go)
func update_mesh_instances():
	while len(mesh_nodes_to_delete) > 0: # remove old MeshInstances and CollisionShapes
		# TODO: aha! found it!
		mesh_nodes_to_delete.pop_back().queue_free()
	if (opaque_mesh_instance != null): add_node_to_delete(opaque_mesh_instance)
	if (transparent_mesh_instance != null): add_node_to_delete(transparent_mesh_instance)
	add_collision_shapes() # add collision shapes AFTER removing previous children
	new_mesh_instance_available = false # no new mesh instances currently available
	updating_mesh = false # can update mesh(es) again now

# override this to associate materials with the surface tools!
func load_materials():
	pass

# override to add colliders to the MeshGrid
func add_collision_shapes():
	pass

# only initialize surface tool if its material has been loaded
func initialize_surface_tools():
	if (opaque_material != null): surface_tool = MeshHelper.get_new_surface_tool()
	if (transparent_material != null): transparent_surface_tool = MeshHelper.get_new_surface_tool()


# adds a box to collide with things at the given coordinates
func add_collision_box(coordinates, cube_scale=Vector3.ONE):
	var collision_shape = CollisionShape3D.new() # make a generic collision shape
	collision_shape.shape = BoxShape3D.new() # make it cube-shaped
	collision_shape.position = Vector3(coordinates[0], coordinates[1], coordinates[2])
	collision_shape.scale = cube_scale
	
	add_node_to_delete(collision_shape)

func add_node_to_delete(node):
	mesh_nodes_to_delete.append(node)
	add_child(node)
