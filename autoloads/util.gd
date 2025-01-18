extends Node


const MAX_FILENAME_LENGTH = 48


func check_config_file(path: String):
	assert(FileAccess.file_exists(path))
	
	var raw_text = FileAccess.open(path, FileAccess.READ).get_as_text()
	var data: Dictionary = JSON.parse_string(raw_text)
	
	assert(data.has("ProjectName"))
	assert(data.has("VersionProject"))
	assert(data.has("VersionEditor"))
	assert(data.has("DefaultStart"))
	assert(data.has("ListSpeakers"))


func is_equal(a: Variant, b: Variant) -> bool:
	var type_a = typeof(a)
	var type_b = typeof(b)
	
	if type_a == type_b:
		match type_a:
			TYPE_DICTIONARY, TYPE_OBJECT:
				return a.hash() == b.hash()
			TYPE_ARRAY:
				if a.size() == b.size():
					var i = 0
					var premise = true
					while i < a.size() and premise:
						premise = is_equal(a[i], b[i])
						i = i + 1
					return premise
			_:
				return a == b
	
	return false


## Check if all elements of array_a is inside of array_b.
func is_inside(array_a: Array, array_b: Array) -> bool:
	for element in array_a:
		if not array_b.has(element):
			return false
	return true


## Converts a snake case name to JSON key format with capitalized "ID".
func to_key_name(snake_case_name: String, delimiter: String = ""):
	var words = snake_case_name.capitalize().split(" ")
	var capitalized_list = PackedStringArray()
	for word in words:
		capitalized_list.append("ID" if word.to_lower() == "id" else word)
	return delimiter.join(capitalized_list)


## Left-truncate a given filename string based on MAX_FILENAME_LENGTH.
func truncate_filename(filename: String):
	var truncated = filename
	if filename.length() > MAX_FILENAME_LENGTH:
		truncated = "..." + filename.right(MAX_FILENAME_LENGTH - 3)
	return truncated
