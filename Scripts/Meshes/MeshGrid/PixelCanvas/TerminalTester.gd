extends Node3D

var terminal: Terminal

func _ready():
	terminal = Terminal.new(80, 25)
	add_child(terminal)
	terminal.position = Vector3(0, 0, 0)
	terminal.rotation_degrees = Vector3(0, 180, 0)
	
	display_welcome_message()

func display_welcome_message():
	terminal.write_string("=== GODOT TERMINAL v1.0 ===\n\n", Color.CYAN)
	terminal.write_string("Welcome to the interactive terminal!\n", Color.GREEN)
	terminal.write_string("Type to see your input...\n\n", Color.WHITE)
	terminal.write_string("> ", Color.YELLOW)
