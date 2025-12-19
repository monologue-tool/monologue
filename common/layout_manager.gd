class_name LayoutManager


static func create_layout(
	schema: Dictionary,
	item: ListItemObject,
	list_field: ListField,
	layout_name: String = "default",
) -> Control:
	var layout_config = _get_layout_config(schema, layout_name)

	var vbox = VBoxContainer.new()
	var fields = _get_fields_to_display(schema, layout_config)
	var properties = schema.get("properties", {})
	var index = list_field.get_item_index(item)

	for field_name in fields:
		if not properties.has(field_name):
			continue

		var field_container = _create_field_container(
			field_name, properties[field_name], list_field, item
		)

		if field_container:
			vbox.add_child(field_container)

	_create_item_header(vbox, index, list_field, item, layout_config)

	return vbox


static func _get_layout_config(schema: Dictionary, layout_name: String) -> Dictionary:
	var layouts = schema.get("layouts", {})
	return layouts.get(layout_name, layouts.get("default", {}))


static func _create_section_header(section_config: Dictionary) -> Control:
	if section_config.get("collapsible", false):
		return _create_collapsible_header(section_config)

	return _create_simple_header(section_config)


static func _create_collapsible_header(section_config: Dictionary) -> Button:
	var button = Button.new()
	button.text = section_config.get("title", "")
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button


static func _create_simple_header(section_config: Dictionary) -> Label:
	var label = Label.new()
	label.text = section_config.get("title", "")
	label.theme_type_variation = "SectionLabel"
	return label


static func _create_field_container(
	field_name: String, field_config: Dictionary, _list_field: ListField, item: ListItemObject
) -> Control:
	var container = VBoxContainer.new()

	var title_container = _create_title_container(field_name, field_config)
	container.add_child(title_container)

	var field = _create_and_configure_field(field_name, field_config, item)
	container.add_child(field)

	var property = item.get_property(field_name)
	if property:
		var merged_settings = field_config.duplicate()
		merged_settings.merge(property.settings, true)
		field.settings = merged_settings

	_bind_field_to_property.call_deferred(field, field_name, item)

	return container


static func _create_title_container(field_name: String, field_config: Dictionary) -> HBoxContainer:
	var title_container = HBoxContainer.new()
	title_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label = Label.new()
	label.text = Util.to_readable_name(field_name)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if field_config.has("tooltip"):
		label.tooltip_text = field_config["tooltip"]

	title_container.add_child(label)
	return title_container


static func _create_and_configure_field(
	_field_name: String, field_config: Dictionary, _item: ListItemObject
) -> Field:
	var field_type: String = field_config.get("type", "text")
	var field: Field = FieldBucket.safe_create_field(field_type)

	if field is Field:
		field.settings = field_config.duplicate()
		field.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	return field


static func _bind_field_to_property(field: Field, field_name: String, item: ListItemObject) -> void:
	var property = item.get_property(field_name)
	if not property:
		push_warning("Property '%s' not found in item" % field_name)
		return

	if field.is_node_ready():
		property.bind_field(field, item)
	else:
		field.ready.connect(func(): property.bind_field(field, item), CONNECT_ONE_SHOT)


static func _get_fields_to_display(schema: Dictionary, layout_config: Dictionary) -> Array:
	var properties = schema.get("properties", {})
	return layout_config.get("fields", properties.keys())


static func _check_condition(condition: Dictionary, item: ListItemObject) -> bool:
	var property_name = condition.get("property", "")

	var property = item.get_property(property_name)
	if not property:
		return false

	var value = property.get_value()

	if condition.has("equals"):
		return value == condition["equals"]

	if condition.has("not_equals"):
		return value != condition["not_equals"]

	if condition.has("in"):
		return value in condition["in"]

	return true


static func _format_string(format: String, item: ListItemObject) -> String:
	var data = item.to_dictionary()
	var result = format
	var regex = RegEx.new()
	regex.compile("\\{([^}]+)\\}")

	for match_result in regex.search_all(format):
		var key = match_result.get_string(1)
		var value = _resolve_path(key, data)
		result = result.replace("{" + key + "}", str(value))

	return result


static func _resolve_path(path: String, data: Dictionary) -> Variant:
	if path.is_empty():
		return ""

	var parts = path.split(".")
	var current = data

	for part in parts:
		current = _resolve_path_part(current, part)
		if current == null:
			return ""

	return current


static func _resolve_path_part(current: Variant, part: String) -> Variant:
	if current is Dictionary:
		return _resolve_dictionary_part(current, part)

	if current is Array:
		return _resolve_array_part(current, part)

	return null


static func _resolve_dictionary_part(dict: Dictionary, part: String) -> Variant:
	if part == "length" or part.ends_with(".length"):
		return 0

	return dict.get(part, null)


static func _resolve_array_part(array: Array, part: String) -> Variant:
	if part == "length":
		return array.size()

	if part.is_valid_int():
		var index = part.to_int()
		if index >= 0 and index < array.size():
			return array[index]

	return null


static func _create_item_header(
	content: Control,
	index: int,
	list_field: ListField,
	item: ListItemObject,
	layout_config: Dictionary
) -> Control:
	var header = _get_or_create_header_container(content)
	var actions = layout_config.get("actions", ["delete"])

	_add_action_buttons(header, actions, index, list_field, item)

	return header


static func _get_or_create_header_container(content: Control) -> HBoxContainer:
	if content.get_child_count() == 0:
		return HBoxContainer.new()

	var first_child = content.get_child(0)
	if not first_child is BoxContainer or first_child.get_child_count() == 0:
		return HBoxContainer.new()

	var header_candidate = first_child.get_child(0)
	if header_candidate is HBoxContainer:
		return header_candidate

	return HBoxContainer.new()


static func _add_action_buttons(
	header: HBoxContainer, actions: Array, index: int, list_field: ListField, item: ListItemObject
) -> void:
	if "edit" in actions:
		_add_edit_button(header, index, list_field)

	if "duplicate" in actions:
		_add_duplicate_button(header, index, list_field)

	if "delete" in actions and not item.is_protected():
		_add_delete_button(header, index, list_field)


static func _add_edit_button(header: HBoxContainer, index: int, list_field: ListField) -> void:
	if not list_field.has_method("_on_edit_item"):
		return

	var button = Button.new()
	button.icon = preload("res://ui/assets/icons/pen.svg")
	button.tooltip_text = "Edit item"
	button.pressed.connect(list_field.call.bind("_on_edit_item", index))
	header.add_child(button)


static func _add_duplicate_button(header: HBoxContainer, index: int, list_field: ListField) -> void:
	if not list_field.has_method("_on_duplicate_item"):
		return

	var button = Button.new()
	button.icon = preload("res://ui/assets/icons/copy.png")
	button.tooltip_text = "Duplicate item"
	button.pressed.connect(list_field.call.bind("_on_duplicate_item", index))
	header.add_child(button)


static func _add_delete_button(header: HBoxContainer, index: int, list_field: ListField) -> void:
	if not list_field.has_method("_on_delete_item"):
		return

	var button = Button.new()
	button.icon = preload("res://ui/assets/icons/trash.svg")
	button.tooltip_text = "Remove item"
	button.pressed.connect(list_field.call.bind("_on_delete_item", index))
	header.add_child(button)


static func _resolve_dynamic_enum(_path: String, _data: Dictionary) -> Array:
	# TODO: Implement full resolution for dynamic enums
	return []
