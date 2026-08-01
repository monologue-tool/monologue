class_name CollectionDocument extends InspectableDocument

var name: String = ""
var _default_value: Array = []


func _init(
	collection_name: String, default_value: Array = [], command_manager: CommandManager = null
) -> void:
	name = collection_name
	_default_value = default_value
	super._init(command_manager)


func initialize_properties() -> void:
	# A collection document is a single property named after the collection itself,
	# holding every item in it.
	define_property(Property.new(name)
		.set_type("collection")
		.default(_default_value)
		.collection(name))


func get_value() -> Array:
	return get_property_value(name)


func get_type() -> String:
	return "collection"


func get_document_name() -> String:
	return name
