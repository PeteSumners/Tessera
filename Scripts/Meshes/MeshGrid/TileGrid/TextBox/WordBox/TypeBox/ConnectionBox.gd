extends TypeBox
class_name ConnectionBox

func _init():
	super()
	prefix = "server ip (click and hit return to connect):\n"
	grid_x_len = 24
	grid_y_len = 3
	initialize_input_chars(NetworkManager.default_server_ip)
	display_input_chars()

func add_input_char(unicode):
	if (unicode == ENTER):
		var ip = PackedByteArray(input_chars).get_string_from_ascii()
		NetworkManager.connect_to_server(ip)
	super(unicode)

func set_machine_id(new_id):
	super(new_id)

func get_networked_object_type():
	return NetworkManager.ObjectType.ConnectionBox
