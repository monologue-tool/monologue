class_name ListItemObject extends InspectableObject

var _schema: Dictionary = {}
var _initial_data: Dictionary = {}

var list_field: ListField


func _init(
	schema: Dictionary,
	initial_data: Dictionary = {},
	command_manager: CommandManager = null,
	_settings: Dictionary = {}
) -> void:
	_schema = schema
	_initial_data = initial_data
	settings = _settings
	super._init(command_manager)


func initialize_properties() -> void:
	var properties_config: Dictionary = _schema.get("properties", {})

	for prop_name in properties_config:
		var prop_config = properties_config[prop_name]
		_define_property_from_config(prop_name, prop_config)


func _define_property_from_config(prop_name: String, prop_config: Dictionary) -> void:
	var prop_value: Variant = _get_initial_value(prop_name, prop_config)
	var prop_type = prop_config.get("type", "text")
	var category = prop_config.get("category", "General")

	var prop_settings: Dictionary = prop_config.duplicate()
	prop_settings.erase("type")
	prop_settings.erase("default")
	prop_settings.erase("category")

	define_property(prop_name, prop_value, prop_type, prop_settings, category)


func make_all_values_unique() -> void:
	var properties_config: Dictionary = _schema.get("properties", {})
	for prop_name in properties_config:
		var prop_config = properties_config[prop_name]
		_make_property_unique(prop_name, prop_config)


func _make_property_unique(prop_name: String, prop_config: Dictionary) -> void:
	var must_be_unique: bool = prop_config.get("unique", false)
	if not must_be_unique or not list_field:
		return

	var prop_value: Variant = get_property_value(prop_name)
	var original_value: Variant = prop_value
	var attempt: int = 0
	var max_attempts: int = 1000

	while _value_exists_in_list(prop_name, prop_value) and attempt < max_attempts:
		attempt += 1

		if original_value is String:
			var end_num: Variant = _get_end_number(original_value)
			if end_num == null:
				prop_value = "%s %d" % [original_value, attempt]
			else:
				var base_str: String = original_value.left(-str(end_num).length()).strip_edges()
				prop_value = "%s %d" % [base_str, end_num + attempt]
		elif original_value is int:
			prop_value = original_value + attempt
		elif original_value is bool:
			break

	var property: Property = get_property(prop_name)
	if property:
		property.value = prop_value


func _value_exists_in_list(prop_name: String, value: Variant) -> bool:
	if not list_field:
		return false

	for item: ListItemObject in list_field._list_items:
		if item == self:
			continue

		var item_prop: Property = item.get_property(prop_name)
		if not item_prop:
			continue

		if item_prop.get_value() == value:
			return true

	return false


func _get_end_number(value: String) -> Variant:
	var regex = RegEx.new()
	regex.compile("\\d+$")
	var result: RegExMatch = regex.search(value)
	if result:
		return int(result.get_string())
	return null


func _get_initial_value(prop_name: String, prop_config: Dictionary) -> Variant:
	if _initial_data.has(prop_name):
		return _initial_data[prop_name]

	var default: Variant = prop_config.get("default")

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


func get_schema() -> Dictionary:
	return _schema


func is_protected() -> bool:
	return get_property("protected") and get_property_value("protected")


func duplicate_item(command_manager: CommandManager = null) -> ListItemObject:
	var duplicate_data = _to_dict()
	duplicate_data.erase("$type")

	if duplicate_data.has("name"):
		duplicate_data["name"] = str(duplicate_data["name"]) + " (Copy)"

	if (
		duplicate_data.has("id")
		and _schema.get("properties", {}).get("id", {}).get("default") is Callable
	):
		var id_generator = _schema["properties"]["id"]["default"]
		duplicate_data["id"] = id_generator.call()

	var new_item: ListItemObject = ListItemObject.new(
		_schema, duplicate_data, command_manager if command_manager else history
	)
	new_item.make_all_values_unique()
	return new_item


func get_type() -> String:
	return _schema.get("title", "ListItem")


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	pass


func get_settings() -> Dictionary:
	return {}
