class_name CollectionDocument extends InspectableDocument

var name: String = ""
var _default_value: Array = []

func _init(collection_name: String, default_value: Array = [], command_manager: CommandManager = null) -> void:
	name = collection_name
	_default_value = default_value
	super._init(command_manager)


func initialize_properties() -> void:
	define_property(name, _default_value, "collection", { "collection": name })


func get_value() -> Array:
	return get_property_value(name)


func get_type() -> String:
	return "collection"
