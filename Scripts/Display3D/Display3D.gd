extends Node3D
class_name Display3D

# Core components
var viewport: SubViewport
var mesh_instance: MeshInstance3D
var ui_root: Control

# Configuration
@export var resolution := Vector2i(800, 600)
@export var physical_scale := 0.01  # meters per pixel
@export var pixel_perfect := true

func _ready():
	setup_viewport()
	setup_mesh()
	setup_ui_container()

func setup_viewport():
	viewport = SubViewport.new()
	viewport.size = resolution
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)

func setup_mesh():
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	var width = resolution.x * physical_scale
	var height = resolution.y * physical_scale
	
	# Simple quad
	var quad = QuadMesh.new()
	quad.size = Vector2(width, height)
	mesh_instance.mesh = quad
	
	# Material
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# FIX: Set render priority to draw on top
	material.render_priority = 1  # Higher values render later (on top)
	
	if pixel_perfect:
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	mesh_instance.material_override = material

func setup_ui_container():
	# Root control that fills viewport
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(ui_root)

# Add any UI node
func add_ui(node: Control):
	ui_root.add_child(node)

func clear_ui():
	for child in ui_root.get_children():
		child.queue_free()
