## Holds the services and hands them out by name.
##
## Lives on the runtime, not a session. What a game collected in the first scene is still
## there in the third.
class_name MonologueServiceIndexer extends MonologueIndex

const BUILT_IN_FOLDER: String = "res://addons/monologue/services/"
const FOLDERS_SETTING: String = "monologue/service_folders"


func _init(problems: Array[MonologueProblem] = []) -> void:
	super(BUILT_IN_FOLDER, FOLDERS_SETTING, problems)


func wanted() -> Script:
	return MonologueService


func names_of(thing: Node) -> PackedStringArray:
	return [(thing as MonologueService).service_name()]


## Takes an Object and not a Node. What a game hands over is already in its scene.
func provide(service_name: String, object: Object, problems: Array[MonologueProblem] = []) -> void:
	_claim(service_name, object, problems)


## Null when nothing answers to that name. A story still plays in a game with no
## inventory.
func get_service(service_name: String) -> Object:
	return _by_name.get(service_name)


## Duck-typed: an object takes part in whichever of the three it answers to.
func clear_all() -> void:
	for object: Object in _by_name.values():
		if object.has_method(&"clear"):
			object.call(&"clear")


func save_all() -> Dictionary:
	var saved: Dictionary = {}
	for service_name: String in _by_name:
		var object: Object = _by_name[service_name]
		if object.has_method(&"save_state"):
			saved[service_name] = object.call(&"save_state")
	return saved


func load_all(data: Dictionary) -> void:
	for service_name: String in data:
		var object: Object = _by_name.get(service_name)
		if object != null and object.has_method(&"load_state"):
			object.call(&"load_state", data[service_name])
