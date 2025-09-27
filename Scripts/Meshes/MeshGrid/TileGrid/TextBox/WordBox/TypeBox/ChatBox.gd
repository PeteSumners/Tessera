extends TypeBox
class_name ChatBox

func set_machine_id(new_id):
	super(new_id)
	if is_local: update_base_color(MeshTextColor.GREEN) # local text box is highlighted green for easy identification
	prefix = str(machine_id) + "> "
	display_input_chars() # keep input chars the same

func get_networked_object_type():
	return NetworkManager.ObjectType.ChatBox
