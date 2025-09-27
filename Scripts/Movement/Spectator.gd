extends Node3D

@export var acceleration_time: float = 2.5
@export var max_speed: float = 20.0
@export var rotation_speed: float = 0.2
@export var inertia_decay: float = 0.95

@export var camera_node_path: NodePath  # Assign in inspector

var velocity: Vector3 = Vector3.ZERO
var target_velocity: Vector3 = Vector3.ZERO

var yaw: float = 0.0     # Affects parent rotation (horizontal)
var pitch: float = 0.0   # Affects camera rotation (vertical)

var camera: Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera = get_node(camera_node_path)

func _input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * rotation_speed
		pitch -= event.relative.y * rotation_speed
		pitch = clamp(pitch, -89, 89)

func _process(delta):
	# --- Apply rotation ---
	rotation_degrees.y = yaw
	camera.rotation_degrees.x = pitch

	# --- Use flattened basis vectors from this node (no vertical tilt) ---
	var forward = global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var right = -global_transform.basis.x
	right.y = 0
	right = right.normalized()


	var input_dir = Vector3.ZERO
	var has_input = false

	if Input.is_key_pressed(KEY_W):
		input_dir += forward
		has_input = true
	if Input.is_key_pressed(KEY_S):
		input_dir -= forward
		has_input = true
	if Input.is_key_pressed(KEY_D):
		input_dir += right
		has_input = true
	if Input.is_key_pressed(KEY_A):
		input_dir -= right
		has_input = true
	if Input.is_key_pressed(KEY_SPACE):
		input_dir += Vector3.UP
		has_input = true
	if Input.is_key_pressed(KEY_SHIFT):
		input_dir -= Vector3.UP
		has_input = true

	input_dir = input_dir.normalized()
	target_velocity = input_dir * max_speed

	if has_input:
		var velocity_diff = target_velocity - velocity
		velocity += velocity_diff * (delta / acceleration_time)
	else:
		velocity *= pow(inertia_decay, delta * 60.0)

	global_translate(velocity * delta)
