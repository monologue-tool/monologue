class_name Util

const MAX_FILENAME_LENGTH: int = 48


static func is_equal(a: Variant, b: Variant) -> bool:
	var type_a: int = typeof(a)
	var type_b: int = typeof(b)
	if type_a == type_b:
		match type_a:
			TYPE_DICTIONARY, TYPE_OBJECT:
				return a.hash() == b.hash()
			TYPE_ARRAY:
				if a.size() == b.size():
					var i: int = 0
					var premise: bool = true
					while i < a.size() and premise:
						premise = is_equal(a[i], b[i])
						i += 1
					return premise
			_:
				return a == b
	return false


static func is_any_inside(array_a: Array, array_b: Array) -> bool:
	for element: Variant in array_a:
		if array_b.has(element):
			return true
	return false


static func to_key_name(snake_case_name: String, delimiter: String = "") -> String:
	var words: PackedStringArray = snake_case_name.capitalize().split(" ")
	var capitalized_list: PackedStringArray = PackedStringArray()
	for word: String in words:
		capitalized_list.append("ID" if word.to_lower() == "id" else word)
	return delimiter.join(capitalized_list)


static func to_readable_name(snake_case_name: String) -> String:
	return to_key_name(snake_case_name, " ")


## Renders a stored property value as text a person can read.
##
## A translatable value is a {language_code: text} dictionary: it shows the requested
## language, or the first language that has anything in it, so an item labelled only in
## French still reads as something. Returns "" when there is nothing to show, which is
## the caller's cue to fall back to a placeholder rather than an id.
static func to_label(value: Variant, language_code: String = "") -> String:
	if value is String:
		return (value as String).strip_edges()

	if value is Dictionary:
		var translations: Dictionary = value
		var preferred: String = str(translations.get(language_code, "")).strip_edges()
		if not preferred.is_empty():
			return preferred
		for key: Variant in translations:
			var text: String = str(translations[key]).strip_edges()
			if not text.is_empty():
				return text
		return ""

	if value == null or value is Array:
		return ""

	return str(value).strip_edges()


static func truncate_filename(filename: String) -> String:
	var truncated: String = filename
	if filename.length() > MAX_FILENAME_LENGTH:
		truncated = "..." + filename.right(MAX_FILENAME_LENGTH - 3)
	return truncated
