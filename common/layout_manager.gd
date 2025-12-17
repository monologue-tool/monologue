class_name LayoutManager


static func create_layout(
	schema: Dictionary,
	item_data: Dictionary,
	layout_name: String = "default",
	context: Dictionary = {}
) -> Control:
	var layouts = schema.get("layouts", {})
	var layout_config = layouts.get(layout_name, layouts.get("default", {}))

	match layout_config.get("layout", "vertical"):
		"horizontal":
			return _create_horizontal_layout(schema, item_data, layout_config, context)
		_:
			return _create_vertical_layout(schema, item_data, layout_config, context)


static func _create_section_header(section_config: Dictionary) -> Control:
	var header: Control

	if section_config.get("collapsible", false):
		var button = Button.new()
		button.text = section_config.get("title", "")
		button.flat = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		header = button
	else:
		var label = Label.new()
		label.text = section_config.get("title", "")
		label.theme_type_variation = "SectionLabel"
		header = label

	return header


static func _create_field_container(
	field_name: String, field_config: Dictionary, item_data: Dictionary, context: Dictionary
) -> Control:
	var container = VBoxContainer.new()

	var title_container: HBoxContainer = HBoxContainer.new()
	title_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label = Label.new()
	label.text = Util.to_readable_name(field_name)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_container.add_child(label)
	container.add_child(title_container)

	if field_config.has("tooltip"):
		label.tooltip_text = field_config["tooltip"]

	var field_type = field_config.get("type", "text")
	var field_value = item_data.get(field_name, field_config.get("default"))
	var field: Field = FieldBucket.create_field(field_type)

	if not field:
		var warn = Label.new()
		warn.text = "Unknown field: " + field_type
		warn.theme_type_variation = "WarnLabel"
		container.add_child(warn)
		return container

	field.settings = field_config
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(field)
	field.set_value.call_deferred(field_value)
	field.initialize.call_deferred()

	field.value_committed.connect(
		func(new_value):
			item_data[field_name] = new_value
			if context.has("on_change"):
				context["on_change"].call(field_name, new_value)
	)

	return container


static func _create_vertical_layout(
	schema: Dictionary, item_data: Dictionary, layout_config: Dictionary, context: Dictionary
) -> Control:
	var vbox = VBoxContainer.new()
	var properties = schema.get("properties", {})
	var fields = layout_config.get("fields", properties.keys())

	for field_name in fields:
		if not properties.has(field_name):
			continue

		var field_container = _create_field_container(
			field_name, properties[field_name], item_data, context
		)

		if field_container:
			vbox.add_child(field_container)

	return vbox


static func _create_horizontal_layout(
	schema: Dictionary, item_data: Dictionary, layout_config: Dictionary, context: Dictionary
) -> Control:
	var hbox = HBoxContainer.new()
	var properties = schema.get("properties", {})
	var fields = layout_config.get("fields", properties.keys())

	for field_name in fields:
		if not properties.has(field_name):
			continue

		var field_config = properties[field_name]
		var field_type = field_config.get("type")
		var field = FieldBucket.create_field(field_type)

		if field:
			field.set_value.call_deferred(item_data.get(field_name, field_config.get("default")))
			hbox.add_child(field)

	return hbox


static func _check_condition(condition: Dictionary, item_data: Dictionary) -> bool:
	var property = condition.get("property", "")
	var value = item_data.get(property)

	if condition.has("equals"):
		return value == condition["equals"]

	if condition.has("not_equals"):
		return value != condition["not_equals"]

	if condition.has("in"):
		return value in condition["in"]

	return true


static func _format_string(format: String, data: Dictionary) -> String:
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
		if current is Dictionary:
			if part.ends_with(".length") or part == "length":
				if current is Array:
					return current.size()
				return 0
			current = current.get(part, null)
		elif current is Array:
			if part.is_valid_int():
				var index = part.to_int()
				if index >= 0 and index < current.size():
					current = current[index]
				else:
					return null
			elif part == "length":
				return current.size()
		else:
			return null

		if current == null:
			return ""

	return current


static func _resolve_dynamic_enum(path: String, data: Dictionary) -> Array:
	# Ex: "characters.{character}.portraits.name"
	# Résout les enums dynamiques basés sur d'autres propriétés

	var result: Array = []

	# TODO: Implémenter la résolution complète
	# Pour l'instant, retourne un array vide

	return result
