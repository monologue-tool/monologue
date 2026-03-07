class_name Util

const MAX_FILENAME_LENGTH = 48


static func is_equal(a: Variant, b: Variant) -> bool:
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
						i += 1
					return premise
			_:
				return a == b
	return false


## Check if any element of array_a is inside array_b.
static func is_any_inside(array_a: Array, array_b: Array) -> bool:
	for element in array_a:
		if array_b.has(element):
			return true
	return false


## Converts a snake_case name to JSON key format with capitalized "ID".
static func to_key_name(snake_case_name: String, delimiter: String = "") -> String:
	var words = snake_case_name.capitalize().split(" ")
	var capitalized_list = PackedStringArray()
	for word in words:
		capitalized_list.append("ID" if word.to_lower() == "id" else word)
	return delimiter.join(capitalized_list)


## Converts a snake_case name to readable string with capitalized "ID".
static func to_readable_name(snake_case_name: String) -> String:
	return to_key_name(snake_case_name, " ")


## Left-truncate a filename string based on MAX_FILENAME_LENGTH.
static func truncate_filename(filename: String) -> String:
	var truncated = filename
	if filename.length() > MAX_FILENAME_LENGTH:
		truncated = "..." + filename.right(MAX_FILENAME_LENGTH - 3)
	return truncated
