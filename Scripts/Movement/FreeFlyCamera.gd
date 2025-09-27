extends Camera3D

@export var move_speed := 10.0
@export var acceleration := 5.0
@export var damping := 4.0
@export var mouse_sensitivity := 0.002

var velocity := Vector3.ZERO
var yaw := 0.0
var pitch := 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	yaw = rotation.y
	pitch = rotation.x

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
		rotation = Vector3(pitch, yaw, 0)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta):
	var input_dir := Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		input_dir.z -= 1
	if Input.is_key_pressed(KEY_S):
		input_dir.z += 1
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_key_pressed(KEY_SPACE):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_SHIFT):
		input_dir.y -= 1

	# Convert local input direction into world space based on current rotation
	var local_direction = input_dir.normalized()
	var basis = Basis.from_euler(rotation)
	var world_direction = basis * local_direction

	# Accelerate and move
	var target_velocity = world_direction * move_speed
	velocity = velocity.lerp(target_velocity, clamp(acceleration * delta, 0.0, 1.0))

	if input_dir == Vector3.ZERO:
		velocity = velocity.lerp(Vector3.ZERO, clamp(damping * delta, 0.0, 1.0))

	translate(velocity * delta)
