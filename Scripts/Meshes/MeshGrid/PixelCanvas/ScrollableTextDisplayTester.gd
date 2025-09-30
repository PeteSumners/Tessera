extends Node3D

var display: ScrollableTextDisplay

func _ready():
	display = ScrollableTextDisplay.new(40, 10)
	add_child(display)
	display.position = Vector3(0, 0, 0)
	display.rotation_degrees = Vector3(0, 180, 0)
	
	demo_blend_modes()

func demo_blend_modes():
	var lines = PackedStringArray([
		"NORMAL BLEND",
		"ADDITIVE BLEND - Colors add together",
		"SUBTRACTIVE BLEND - Colors subtract",
		"",
		"Mix: NORMAL + ADDITIVE + SUBTRACTIVE",
		"AAAAAAAAAA",
		"BBBBBBBBBB",
		"CCCCCCCCCC"
	])
	
	var colors: Array[Color] = [
		Color.WHITE,
		Color(1, 0.5, 0, 1),    # Orange
		Color(0, 0.5, 1, 1),    # Blue
		Color.WHITE,
		Color.YELLOW,
		Color(1, 0, 0, 0.7),    # Semi-transparent red
		Color(0, 1, 0, 0.7),    # Semi-transparent green
		Color(0, 0, 1, 0.7)     # Semi-transparent blue
	]
	
	var blend_modes: Array[ScrollableTextDisplay.BlendMode] = [
		ScrollableTextDisplay.BlendMode.NORMAL,
		ScrollableTextDisplay.BlendMode.ADDITIVE,
		ScrollableTextDisplay.BlendMode.SUBTRACTIVE,
		ScrollableTextDisplay.BlendMode.NORMAL,
		ScrollableTextDisplay.BlendMode.NORMAL,
		ScrollableTextDisplay.BlendMode.ADDITIVE,
		ScrollableTextDisplay.BlendMode.ADDITIVE,
		ScrollableTextDisplay.BlendMode.SUBTRACTIVE
	]
	
	display.set_styled_content(lines, colors, blend_modes)
