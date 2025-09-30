extends Node3D

var canvas: PixelCanvas
var animation_time: float = 0.0
var current_mode: int = 0
const MODE_RIPPLE = 0
const MODE_COLOR_WHEEL = 1
const MODE_PLASMA = 2

func _ready():
	canvas = PixelCanvas.new(100, 100, 0.01)
	add_child(canvas)
	canvas.position = Vector3(0, 0, 0)

func _process(delta):
	animation_time += delta
	
	match current_mode:
		MODE_RIPPLE:
			update_ripple()
		MODE_COLOR_WHEEL:
			update_color_wheel()
		MODE_PLASMA:
			update_plasma()
	
	canvas.update_texture()

func update_ripple():
	var center = Vector2(canvas.width / 2.0, canvas.height / 2.0)
	
	for y in range(canvas.height):
		for x in range(canvas.width):
			var dist = Vector2(x, y).distance_to(center)
			var wave = sin(dist * 0.2 - animation_time * 3.0) * 0.5 + 0.5
			canvas.set_pixel(x, y, Color(wave, wave, 1.0, 1.0))

func update_color_wheel():
	var center = Vector2(canvas.width / 2.0, canvas.height / 2.0)
	var radius = min(canvas.width, canvas.height) / 2.0
	
	for y in range(canvas.height):
		for x in range(canvas.width):
			var dir = Vector2(x, y) - center
			var distance = dir.length()
			
			if distance <= radius:
				var angle = atan2(dir.y, dir.x) + animation_time
				var hue = fmod((angle / TAU) + 1.0, 1.0)
				var saturation = 1.0 - (distance / radius) * 0.3
				var brightness = 1.0
				
				var color = Color.from_hsv(hue, saturation, brightness)
				canvas.set_pixel(x, y, color)
			else:
				canvas.set_pixel(x, y, Color.BLACK)

func update_plasma():
	for y in range(canvas.height):
		for x in range(canvas.width):
			var v1 = sin(x * 0.1 + animation_time)
			var v2 = sin(y * 0.1 + animation_time)
			var v3 = sin((x + y) * 0.1 + animation_time)
			var v4 = sin(sqrt(x * x + y * y) * 0.1 + animation_time)
			
			var value = (v1 + v2 + v3 + v4) / 4.0
			var hue = (value + 1.0) / 2.0
			
			var color = Color.from_hsv(hue, 0.8, 0.9)
			canvas.set_pixel(x, y, color)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			current_mode = (current_mode + 1) % 3
			print("Mode: ", ["Ripple", "Color Wheel", "Plasma"][current_mode])
