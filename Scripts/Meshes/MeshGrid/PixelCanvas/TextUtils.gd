class_name TextUtils

# Word wrap text to fit within max_cols, breaking at word boundaries when possible
static func word_wrap(text: String, max_cols: int) -> PackedStringArray:
	if max_cols <= 0:
		push_error("word_wrap: max_cols must be positive")
		return PackedStringArray([text])
	
	var lines = PackedStringArray()
	var paragraphs = text.split("\n")
	
	for paragraph in paragraphs:
		if paragraph.strip_edges().is_empty():
			lines.append("")
			continue
		
		var words = paragraph.split(" ", false)  # false = don't include empty strings
		var current_line = ""
		
		for word in words:
			# Calculate what the line would be with this word added
			var test_line = current_line
			if current_line.length() > 0:
				test_line += " "
			test_line += word
			
			if test_line.length() <= max_cols:
				# Word fits, add it
				current_line = test_line
			else:
				# Word doesn't fit
				if current_line.length() > 0:
					# Save current line
					lines.append(current_line)
					current_line = ""
				
				# Handle word longer than max_cols (hard break it)
				if word.length() > max_cols:
					while word.length() > max_cols:
						lines.append(word.substr(0, max_cols))
						word = word.substr(max_cols)
					current_line = word
				else:
					current_line = word
		
		# Don't forget the last line of the paragraph
		if current_line.length() > 0:
			lines.append(current_line)
	
	return lines

# Hard wrap - break at exact column boundary (for terminal-style display)
static func hard_wrap(text: String, max_cols: int) -> PackedStringArray:
	if max_cols <= 0:
		push_error("hard_wrap: max_cols must be positive")
		return PackedStringArray([text])
	
	var lines = PackedStringArray()
	var current_pos = 0
	
	while current_pos < text.length():
		var chunk = text.substr(current_pos, max_cols)
		
		# Check for newline within chunk
		var newline_pos = chunk.find("\n")
		if newline_pos != -1:
			lines.append(chunk.substr(0, newline_pos))
			current_pos += newline_pos + 1
		else:
			lines.append(chunk)
			current_pos += max_cols
	
	return lines

# Center text within a given width
static func pad_center(text: String, width: int, fill_char: String = " ") -> String:
	var padding = width - text.length()
	if padding <= 0:
		return text
	var left = padding / 2
	var right = padding - left
	return fill_char.repeat(left) + text + fill_char.repeat(right)

# Pad text to the right
static func pad_right(text: String, width: int, fill_char: String = " ") -> String:
	var padding = width - text.length()
	if padding <= 0:
		return text
	return text + fill_char.repeat(padding)

# Pad text to the left
static func pad_left(text: String, width: int, fill_char: String = " ") -> String:
	var padding = width - text.length()
	if padding <= 0:
		return text
	return fill_char.repeat(padding) + text

# Truncate with ellipsis if too long
static func truncate_with_ellipsis(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	if max_length < 3:
		return text.substr(0, max_length)
	return text.substr(0, max_length - 3) + "..."
