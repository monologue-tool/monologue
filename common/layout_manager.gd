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

		vbox.add_child(field_container)

	_create_item_header(vbox, index, list_field, item, layout_config)

	return vbox


static func _get_layout_config(schema: Dictionary, layout_name: String) -> Dictionary:
	var layouts = schema.get("layouts", {})
	return layouts.get(layout_name, layouts.get("default", {}))


static func _create_field_container(
	field_name: String, field_config: Dictionary, _list_field: ListField, item: ListItemObject
) -> Control:
	var container: VBoxContainer = VBoxContainer.new()

	var title_container: HBoxContainer = _create_title_container(field_name, field_config)
	container.add_child(title_container)

	var field: Field = _create_and_configure_field(field_name, field_config, item)
	container.add_child(field)

	var property: Property = item.get_property(field_name)
	if property:
		var merged_settings: Dictionary = field_config.duplicate()
		merged_settings.merge(property.get_settings(), true)
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
	var field_type: String = field_config.get("type")
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
		return
	field.ready.connect(func(): property.bind_field(field, item), CONNECT_ONE_SHOT)


static func _get_fields_to_display(schema: Dictionary, layout_config: Dictionary) -> Array:
	var properties = schema.get("properties", {})
	return layout_config.get("fields", properties.keys())


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
		_add_button(
			header, index, list_field, "edit", "Edit item", preload("res://ui/assets/icons/pen.svg")
		)

	if "duplicate" in actions:
		_add_button(
			header,
			index,
			list_field,
			"duplicate",
			"Duplicate item",
			preload("res://ui/assets/icons/copy.png")
		)

	if "delete" in actions and not item.is_protected():
		_add_button(
			header,
			index,
			list_field,
			"delete",
			"Delete item",
			preload("res://ui/assets/icons/trash.svg")
		)


static func _add_button(
	header: HBoxContainer,
	index: int,
	list_field: ListField,
	action_name: String,
	tooltip: String,
	icon: Texture2D
) -> void:
	if not list_field.has_method("_on_%s_item" % action_name):
		return

	var button = Button.new()
	button.icon = icon
	button.tooltip_text = tooltip
	button.pressed.connect(list_field.call.bind("_on_%s_item" % action_name, index))
	header.add_child(button)


static func _resolve_dynamic_enum(_path: String, _data: Dictionary) -> Array:
	# TODO: Implement full resolution for dynamic enums
	return []
