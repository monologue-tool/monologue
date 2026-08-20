## Makes a saved document smaller.
##
## [method pack] and [method unpack] are inverses over any document.
##
## It walks the whole tree rather than the top level, so an option inside a choice and a
## record inside a collection are shortened the same way a node is.
class_name MonologueCompactor

const ALIASES_KEY: String = "_aliases"
const PROTOTYPES_KEY: String = "_prototypes"
const PREFIX: String = "^"
const TYPE_KEY: String = "$type"
const MIN_USES: int = 3
const MIN_LENGTH: int = 4
const POOL: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%&*"


static func pack(document: Dictionary) -> Dictionary:
	var tally: Dictionary = {}
	_tally_keys(document, tally)

	var aliases: Dictionary = _aliases_for(tally)
	var shortened: Dictionary = {}
	for alias: String in aliases:
		shortened[aliases[alias]] = alias

	var prototypes: Dictionary = _prototypes_of(document)
	var packed: Dictionary = _shrink(document, prototypes, shortened)

	if not aliases.is_empty():
		packed[ALIASES_KEY] = aliases
	if not prototypes.is_empty():
		packed[PROTOTYPES_KEY] = prototypes
	return packed


## A document that was never packed comes back untouched, so this is safe to run on anything
## arriving from anywhere.
static func unpack(document: Dictionary) -> Dictionary:
	if not document.has(ALIASES_KEY) and not document.has(PROTOTYPES_KEY):
		return document

	var body: Dictionary = document.duplicate()
	body.erase(ALIASES_KEY)
	body.erase(PROTOTYPES_KEY)

	return _grow(body, document.get(PROTOTYPES_KEY, {}), document.get(ALIASES_KEY, {}))


static func _tally_keys(value: Variant, tally: Dictionary) -> void:
	if value is Dictionary:
		for key: Variant in (value as Dictionary):
			tally[key] = 1 + int(tally.get(key, 0))
			_tally_keys((value as Dictionary)[key], tally)
	elif value is Array:
		for held: Variant in (value as Array):
			_tally_keys(held, tally)


## alias -> name, shortest aliases going to whichever keys cost the most, which is how often
## they appear times how long they are.
static func _aliases_for(tally: Dictionary) -> Dictionary:
	var worth_it: Array[String] = []
	for key: Variant in tally:
		var name: String = str(key)
		if name != TYPE_KEY and name.length() >= MIN_LENGTH and int(tally[key]) >= MIN_USES:
			worth_it.append(name)

	worth_it.sort_custom(
		func(first: String, second: String) -> bool:
			return int(tally[first]) * first.length() > int(tally[second]) * second.length()
	)

	var aliases: Dictionary = {}
	for index: int in worth_it.size():
		aliases[_code(index)] = worth_it[index]
	return aliases


static func _code(index: int) -> String:
	if index < POOL.length():
		return PREFIX + POOL[index]

	var high: int = index / POOL.length() - 1
	return PREFIX + POOL[high % POOL.length()] + POOL[index % POOL.length()]


static func _prototypes_of(document: Dictionary) -> Dictionary:
	var by_type: Dictionary = {}
	_gather_by_type(document, by_type)

	var prototypes: Dictionary = {}
	for type_name: String in by_type:
		var instances: Array = by_type[type_name]
		if instances.size() < 2:
			continue

		var shared: Dictionary = {}
		for key: Variant in (instances[0] as Dictionary):
			if str(key) == TYPE_KEY or not _carried_by_all(instances, key):
				continue

			var common: Dictionary = _most_common(instances, key)
			if int(common.get("hits", 0)) >= 2:
				shared[key] = common["value"]

		if not shared.is_empty():
			prototypes[type_name] = shared
	return prototypes


static func _gather_by_type(value: Variant, by_type: Dictionary) -> void:
	if value is Dictionary:
		var held: Dictionary = value
		if held.has(TYPE_KEY):
			var listed: Array = by_type.get_or_add(str(held[TYPE_KEY]), [])
			listed.append(held)
		for key: Variant in held:
			_gather_by_type(held[key], by_type)
	elif value is Array:
		for held: Variant in (value as Array):
			_gather_by_type(held, by_type)


static func _carried_by_all(instances: Array, key: Variant) -> bool:
	for one: Variant in instances:
		if not (one as Dictionary).has(key):
			return false
	return true


static func _most_common(instances: Array, key: Variant) -> Dictionary:
	var tally: Dictionary = {}
	var best: String = ""
	var hits: int = 0

	for one: Variant in instances:
		var token: String = JSON.stringify((one as Dictionary)[key])
		var seen: int = 1 + int(tally.get(token, 0))
		tally[token] = seen
		if seen > hits:
			best = token
			hits = seen

	return {"value": JSON.parse_string(best), "hits": hits}


static func _shrink(value: Variant, prototypes: Dictionary, shortened: Dictionary) -> Variant:
	if value is Array:
		var listed: Array = []
		for held: Variant in (value as Array):
			listed.append(_shrink(held, prototypes, shortened))
		return listed

	if value is not Dictionary:
		return value

	var held_dict: Dictionary = value
	var shared: Dictionary = prototypes.get(str(held_dict.get(TYPE_KEY, "")), {})
	var packed: Dictionary = {}

	for key: Variant in held_dict:
		if shared.has(key) and JSON.stringify(shared[key]) == JSON.stringify(held_dict[key]):
			continue
		packed[shortened.get(key, key)] = _shrink(held_dict[key], prototypes, shortened)
	return packed


static func _grow(value: Variant, prototypes: Dictionary, aliases: Dictionary) -> Variant:
	if value is Array:
		var listed: Array = []
		for held: Variant in (value as Array):
			listed.append(_grow(held, prototypes, aliases))
		return listed

	if value is not Dictionary:
		return value

	var held_dict: Dictionary = value
	var grown: Dictionary = {}
	for key: Variant in held_dict:
		var name: Variant = aliases.get(key, key) if str(key).begins_with(PREFIX) else key
		grown[name] = _grow(held_dict[key], prototypes, aliases)

	var shared: Dictionary = prototypes.get(str(grown.get(TYPE_KEY, "")), {})
	for key: Variant in shared:
		if not grown.has(key):
			grown[key] = _duplicated(shared[key])
	return grown


## A prototype value handed to two instances must not be the same object, or editing one
## would change the other.
static func _duplicated(value: Variant) -> Variant:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value is Array:
		return (value as Array).duplicate(true)
	return value
