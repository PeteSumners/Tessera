extends PhysicsObject

var display: PixelDisplay
var current_pattern = 0
var time_elapsed = 0.0
var pattern_time = 0.0
var update_interval = 0.1
var pattern_duration = 5.0
const NUM_PATTERNS = 3

func _ready():
	display = PixelDisplay.new(50, 50)
	add_child(display)
	display.position = Vector3(0, 0, 0)
	display.rotation_degrees = Vector3(0, 180, 0)

func _process(delta):
	time_elapsed += delta
	pattern_time += delta
	
	if pattern_time >= pattern_duration:
		pattern_time = 0.0
		current_pattern = (current_pattern + 1) % NUM_PATTERNS
	
	if time_elapsed >= update_interval:
		time_elapsed = 0.0
		match current_pattern:
			0: update_color_wheel()
			1: update_translucent_display()
			2: update_ripple()

func update_ripple():
	var center = display.get_center()
	var time_factor = Time.get_ticks_msec() / 500.0
	var dims = display.get_pixel_dimensions()
	var width = int(dims.x)
	var height = int(dims.y)
	
	for y in range(height):
		for x in range(width):
			var dist = Vector2(x, y).distance_to(center)
			var wave = 0.5 + 0.5 * sin(dist - time_factor)
			display.set_pixel(x, y, [wave, wave, 1.0, wave])


func update_translucent_display():
	var time = Time.get_ticks_msec() / 1000.0
	var dims = display.get_pixel_dimensions()
	var width = int(dims.x)
	var height = int(dims.y)
	
	for y in range(height):
		for x in range(width):
			var uv = display.to_normalized_coords(x, y)
			var timeOffset = uv.x * PI * 2 + time
			var wave1 = sin(timeOffset) * 0.5 + 0.5
			var wave2 = cos(uv.y * PI * 2 - time) * 0.5 + 0.5
			var wave3 = sin((uv.x + uv.y) * PI * 2 + time) * 0.5 + 0.5

			display.set_pixel(x, y, [
				wave1,  # Red
				wave2,  # Green
				wave3,  # Blue
				0.5     # Constant 50% transparency
			])

func update_color_wheel():
	var dims = display.get_pixel_dimensions()
	var time = Time.get_ticks_msec() / 1000.0

	# Get center in normalized coordinates
	var center = Vector2(0.5, 0.5)  # Center in normalized coordinates
	var radius = 0.5  # Define the radius of the color wheel (relative to the display size)

	# Loop through each pixel using normalized coordinates
	for y in range(int(dims.y)):
		for x in range(int(dims.x)):
			# Convert pixel (x, y) to normalized coordinates using the helper method
			var rel_coords = display.to_normalized_coords(x, y)
			
			# Calculate the distance from the center
			var distance_from_center = rel_coords.distance_to(center)
			
			# Check if the pixel is inside the circle
			if distance_from_center <= radius:
				# Direction vector in normalized space
				var dir = rel_coords - center  
				var angle = atan2(dir.y, dir.x) + time  # Calculate angle based on direction
				var hue = fmod((angle / TAU) + 1.0, 1.0)  # Normalize hue value

				# Adjust the saturation and brightness for a smooth gradient effect
				var saturation = 1.0 - (distance_from_center / radius)  # Decrease saturation with distance
				var brightness = 1.0 - (distance_from_center / radius * 0.2)  # Decrease brightness a bit on edges
				
				# Smooth transition for a more natural edge
				var smooth_factor = smoothstep(0.4, 0.5, distance_from_center / radius)
				var color = Color.from_hsv(hue, saturation * smooth_factor, brightness)  # Create the color from the hue

				# Set the pixel at (x, y) in absolute coordinates
				display.set_pixel(x, y, [color.r, color.g, color.b, 1.0])
			else:
				# Optionally, set the pixel outside the circle to transparent or another color
				display.set_pixel(x, y, [0.0, 0.0, 0.0, 0.0])  # Transparent pixel
