extends Node3D

var reader: BibleReader

func _ready():
	reader = BibleReader.new()
	add_child(reader)
	reader.position = Vector3(0, 0, 0)
	#reader.rotation_degrees = Vector3(0, 180, 0)
	
	print("Bible Reader Controls:")
	print("  UP/DOWN - Scroll by 3 lines")
	print("  PAGEUP/PAGEDOWN - Scroll by page")
	print("  LEFT/RIGHT - Previous/Next chapter")
	print("  Mouse wheel - Scroll")
