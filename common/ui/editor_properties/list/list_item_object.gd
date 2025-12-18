class_name ListItemObject extends InspectableObject

var _schema: Dictionary = {}
var _initial_data: Dictionary = {}


func _init(
	schema: Dictionary, initial_data: Dictionary = {}, command_manager: CommandManager = null
) -> void:
	_schema = schema
	_initial_data = initial_data
	super._init(command_manager)


func initialize_properties() -> void:
	var properties_config = _schema.get("properties", {})

	for prop_name in properties_config:
		var prop_config = properties_config[prop_name]
		_define_property_from_config(prop_name, prop_config)


func _define_property_from_config(prop_name: String, prop_config: Dictionary) -> void:
	var prop_value = _get_initial_value(prop_name, prop_config)
	var prop_type = prop_config.get("type", "text")
	var category = prop_config.get("category", "General")

	var prop_settings = prop_config.duplicate()
	prop_settings.erase("type")
	prop_settings.erase("default")
	prop_settings.erase("category")

	define_property(prop_name, prop_value, prop_type, prop_settings, category)


func _get_initial_value(prop_name: String, prop_config: Dictionary) -> Variant:
	if _initial_data.has(prop_name):
		return _initial_data[prop_name]

	var default = prop_config.get("default")

	if default is Callable:
		return default.call()

	if default != null:
		return default

	return _get_default_for_type(prop_config.get("type", "text"))


func _get_default_for_type(type: String) -> Variant:
	match type:
		"bool":
			return false
		"number", "int", "float":
			return 0
		"text", "textarea", "dropdown":
			return ""
		"list":
			return []
		"vector2":
			return Vector2.ZERO
		"vector3":
			return Vector3.ZERO
		_:
			return null


func to_dictionary() -> Dictionary:
	return _to_dict()


func update_from_dictionary(data: Dictionary) -> void:
	for prop_name in data:
		if _properties.has(prop_name):
			set_property_value(prop_name, data[prop_name])


func get_schema() -> Dictionary:
	return _schema


func is_protected() -> bool:
	return _properties.has("protected") and get_property_value("protected")


func duplicate_item(command_manager: CommandManager = null) -> ListItemObject:
	var duplicate_data = to_dictionary()
	duplicate_data.erase("$type")  # ?

	if duplicate_data.has("protected"):
		duplicate_data["protected"] = false

	if duplicate_data.has("name"):
		duplicate_data["name"] = str(duplicate_data["name"]) + " (Copy)"

	if (
		duplicate_data.has("id")
		and _schema.get("properties", {}).get("id", {}).get("default") is Callable
	):
		var id_generator = _schema["properties"]["id"]["default"]
		duplicate_data["id"] = id_generator.call()

	return ListItemObject.new(
		_schema, duplicate_data, command_manager if command_manager else history
	)


func get_type() -> String:
	return _schema.get("title", "ListItem")


func _on_property_changed(pname: String, old_value: Variant, new_value: Variant) -> void:
	pass


func get_settings() -> Dictionary:
	return {}
