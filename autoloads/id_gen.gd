## Generates the random part of object ids.
class_name IDGen

## Crockford base32: no I, L, O or U, so an id copied by hand out of a bug report
## cannot be read two ways.
const ALPHABET: String = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
const DEFAULT_LENGTH: int = 8

static var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Returns a random string of [param length] Crockford base32 characters.
static func generate(length: int = DEFAULT_LENGTH) -> String:
	var id: String = ""
	for _i: int in range(length):
		id += ALPHABET[_rng.randi_range(0, ALPHABET.length() - 1)]
	return id


## Returns an object id such as "character-7QK2M9XZ". The type prefix makes an id
## readable on its own. The suffix makes it unique.
static func generate_object_id(type_name: String, length: int = DEFAULT_LENGTH) -> String:
	return "%s-%s" % [type_name, generate(length)]


static func get_type_prefix(object_id: String) -> String:
	var separator_index: int = object_id.rfind("-")
	return object_id.substr(0, separator_index) if separator_index > 0 else ""
