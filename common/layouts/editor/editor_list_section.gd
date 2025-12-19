extends PanelContainer

@export var section_icon: Texture2D

var _property: Property
var _list_field: ListField
var _property_owner: InspectableObject

@onready var vbox := %VBox
@onready var search_bar: LineEdit = %SearchLine
@onready var add_button: Button = $VBox/ToolBar/AddButton


func _ready() -> void:
	search_bar.placeholder_text = "Filter %s" % name.to_lower()
	if add_button:
		add_button.pressed.connect(_on_add_button_pressed)


func clear() -> void:
	for child in vbox.get_children():
		child.queue_free()


func load_items(property: Property, property_owner: InspectableObject = null) -> void:
	clear()
	_property = property
	_property_owner = property_owner

	if not _property:
		return

	_list_field = FieldBucket.safe_create_field(_property.type)
	if _list_field is ListField:
		_property.bind_field(_list_field, _property_owner)
	vbox.add_child(_list_field)


func _on_add_button_pressed() -> void:
	if _property and _property_owner:
		var source_value: Variant = _property.get_value()
		var current_list: Array = []
		if source_value is Array:
			current_list = (source_value as Array).duplicate(true)

		var data_schema = _property.settings.get("data_schema", {})
		var schema_properties: Dictionary = data_schema.get("properties", {})
		var new_item: Dictionary = {}
		for prop_name in schema_properties.keys():
			var prop_config = schema_properties[prop_name]

			if prop_config.get("editor_only", false):
				continue

			new_item[prop_name] = prop_config.get("default", "")
			if prop_config.get("default") is Callable:
				new_item[prop_name] = new_item[prop_name].call()

			if prop_config.get("unique", false):
				var existing_values: Array = []
				var item_list: Array = _list_field.get_value()
				for item: Dictionary in item_list:
					if item.has(prop_name):
						existing_values.append(item.get(prop_name))

				new_item[prop_name] = _make_unique(new_item[prop_name], existing_values)

		current_list.append(new_item)
		_property_owner.set_property_value(_property.name, current_list)


func _make_unique(base: String, existing: Array) -> String:
	if not existing.has(base):
		return base

	var counter = 1
	var unique_name = "%s %s" % [base, counter]

	while existing.has(unique_name):
		counter += 1
		unique_name = "%s %s" % [base, counter]

	return unique_name


func _on_search_line_text_changed(new_text: String) -> void:
	_list_field.show_all_items()
	if new_text.is_empty():
		return

	var search_keys: Array[String] = ["name", "display_name", "nicknames", "description"]
	var item_list: Array = _list_field.get_value()

	for item: Dictionary in item_list:
		var hide_item: bool = true
		var item_idx: int = item_list.find(item)
		for prop: String in item.keys().filter(func(k): return k in search_keys):
			var value: Variant = item[prop]
			if value is not String:
				continue

			if new_text.to_lower() in value.to_lower():
				hide_item = false
		if hide_item:
			_list_field.hide_item(item_idx)
