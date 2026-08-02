## Makes up a plausible person name, used as the default name of a new character.
##
## The lists live in res://common/data/ as one name per line rather than in this file:
## they are data, not code, and a text file can be corrected by someone who does not
## write GDScript. Each list is read once, on the first call that needs it.
##
## 2000 names per list, sampled across the alphabet from
## https://cerol.itch.io/godot-name-generator-class
class_name NameGenerator

const FEMALE_FIRST_NAMES_PATH: String = "res://common/data/first_names_female.txt"
const MALE_FIRST_NAMES_PATH: String = "res://common/data/first_names_male.txt"
const LAST_NAMES_PATH: String = "res://common/data/last_names.txt"

static var _cache: Dictionary[String, PackedStringArray] = {}


## Returns a name such as "Ada Zysk", or "" when the lists could not be read.
static func generate() -> String:
	var first_names: PackedStringArray = get_names(
		[FEMALE_FIRST_NAMES_PATH, MALE_FIRST_NAMES_PATH].pick_random()
	)
	var last_names: PackedStringArray = get_names(LAST_NAMES_PATH)
	if first_names.is_empty() or last_names.is_empty():
		return ""

	return "%s %s" % [_pick(first_names), _pick(last_names)]


## Every name in one list, in file order. Empty when the file cannot be read.
static func get_names(path: String) -> PackedStringArray:
	if _cache.has(path):
		return _cache[path]

	var names: PackedStringArray = []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not read the name list at '%s'." % path)
	else:
		while not file.eof_reached():
			var line: String = file.get_line().strip_edges()
			if not line.is_empty():
				names.append(line)
		file.close()

	_cache[path] = names
	return names


## Forgets the cached lists so the next call reads the files again. Tests only.
static func clear_cache() -> void:
	_cache.clear()


static func _pick(names: PackedStringArray) -> String:
	return names[randi() % names.size()]
