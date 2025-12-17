class_name ListField extends Field

const FIELD_VARIANT_CASES_KEY := "cases"
const FIELD_VARIANT_DEFAULT_KEY := "_default"
const FIELD_COERCE_KEY := "coerce"
const FIELD_OPTIONS_KEY := "options"
const NORMALIZE_ITERATIONS := 4

var _list_items: Array = []
var _hide_items: Array = []
var _data_schema: Dictionary = {}
var _template_keys: Array = []
var _field_dependencies: Dictionary = {}
var _layout: String = "default"

@onready var items_container: VBoxContainer = %ItemsContainer


func _ready() -> void:
	super._ready()


func hide_item(idx: int) -> void:
	_hide_items.append(idx)
	_rebuild_ui()


func show_all_items() -> void:
	_hide_items.clear()
	_rebuild_ui()


func set_value(value: Variant) -> void:
	if value is Array:
		_list_items = value.duplicate(true)
	else:
		_list_items = []
	_rebuild_ui()


func get_value() -> Variant:
	return _list_items.duplicate(true)


func set_editable(is_editable: bool) -> void:
	if is_instance_valid(items_container):
		for child in items_container.get_children():
			if child.has_method("set_editable"):
				child.set_editable(is_editable)


func _on_initialize() -> void:
	super._on_initialize()
	if _binding and _binding.property:
		var property: Property = _binding.property
		_data_schema = property.settings.get("data_schema", {})
		_layout = property.settings.get("layout", "default")
		_template_keys = _data_schema.keys()
		_register_field_dependencies()

	if not is_node_ready():
		await ready
	_rebuild_ui()


func _rebuild_ui() -> void:
	if not is_instance_valid(items_container):
		return

	for child in items_container.get_children():
		items_container.remove_child(child)
		child.queue_free()

	for i in range(_list_items.size()):
		if i in _hide_items:
			continue

		var item_ui = _create_item_ui(i)
		if item_ui:
			items_container.add_child(item_ui)


func _create_item_ui(index: int) -> Control:
	var item_data = _list_items[index]

	if not item_data is Dictionary:
		item_data = {}
		_list_items[index] = item_data

	_normalize_item(item_data)

	var item_container = PanelContainer.new()
	item_container.theme_type_variation = "ListItemContainer"

	var main_vbox = VBoxContainer.new()
	item_container.add_child(main_vbox)

	var context = {
		"on_change":
		func(field_name: String, new_value: Variant):
			_on_item_field_changed(index, field_name, new_value)
	}

	var content = LayoutManager.create_layout(_data_schema, item_data, _layout, context)

	_create_item_header(content, index, item_data)

	if content:
		main_vbox.add_child(content)

	return item_container


func _create_item_header(content: Control, index: int, item_data: Dictionary) -> Control:
	var header: HBoxContainer = HBoxContainer.new()

	if content.get_child_count() > 0:
		var first_prop: BoxContainer = content.get_child(0)
		if first_prop.get_child_count() > 0:
			var header_candidate: Control = first_prop.get_child(0)
			if header_candidate is HBoxContainer:
				header = header_candidate

	#var title_text = "Item " + str(index + 1)

	#var layouts = _data_schema.get("layouts", {})
	#var layout_config = layouts.get(_layout, {})

	#if layout_config.has("title_format"):
	#title_text = _format_title(layout_config["title_format"], item_data)

	#var title_label = Label.new()
	#title_label.text = title_text
	#title_label.theme_type_variation = "ListItemTitle"
	#title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#header.add_child(title_label)

	var duplicate_button = Button.new()
	duplicate_button.icon = (
		preload("res://ui/assets/icons/copy.png")
		if ResourceLoader.exists("res://ui/assets/icons/copy.png")
		else null
	)
	duplicate_button.tooltip_text = "Duplicate item"
	duplicate_button.pressed.connect(_on_duplicate_item.bind(index))
	header.add_child(duplicate_button)

	var delete_button = Button.new()
	delete_button.icon = (
		preload("res://ui/assets/icons/trash.svg")
		if ResourceLoader.exists("res://ui/assets/icons/trash.svg")
		else null
	)
	delete_button.tooltip_text = "Remove item"
	delete_button.pressed.connect(_on_delete_item.bind(index))

	if item_data.get("protected", false):
		delete_button.disabled = true
		delete_button.tooltip_text = "This item is protected"

	header.add_child(delete_button)

	return header


func _normalize_item(item_data: Dictionary) -> void:
	var properties = _data_schema.get("properties", {})

	for prop_name in properties:
		var prop_config = properties[prop_name]

		if not item_data.has(prop_name):
			item_data[prop_name] = prop_config.get(
				"default", _get_default_for_type(prop_config.get("type", "text"))
			)
			if item_data[prop_name] is Callable:
				item_data[prop_name] = item_data[prop_name].call()

		if prop_config.has("coerce"):
			item_data[prop_name] = _coerce_value(item_data[prop_name], prop_config["coerce"])


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


func _format_title(format: String, data: Dictionary) -> String:
	var result = format
	var regex = RegEx.new()
	regex.compile("\\{([^}]+)\\}")

	for match_result in regex.search_all(format):
		var key = match_result.get_string(1)
		var value = data.get(key, "")
		result = result.replace("{" + key + "}", str(value))

	return result


func _on_item_field_changed(index: int, field_name: String, new_value: Variant) -> void:
	if index < 0 or index >= _list_items.size():
		return

	var item_data = _list_items[index]
	if not (item_data is Dictionary):
		return

	item_data[field_name] = new_value

	_normalize_item(item_data)

	if _has_dependent_fields(field_name):
		call_deferred("_rebuild_ui")

	_emit_snapshot()


func _on_item_property_changed(
	item_index: int, prop_name: String, new_value: Variant, base_config: Dictionary
) -> void:
	if item_index < 0 or item_index >= _list_items.size():
		return

	var item_data = _list_items[item_index]
	if not (item_data is Dictionary):
		return

	var resolved_config := _resolve_field_settings(base_config, item_data)
	var value_to_store: Variant = new_value
	if resolved_config.has(FIELD_COERCE_KEY):
		value_to_store = _coerce_value(new_value, str(resolved_config[FIELD_COERCE_KEY]))

	if item_data.get(prop_name, null) == value_to_store:
		return

	item_data[prop_name] = value_to_store
	_normalize_item_for_template(item_data)
	_emit_snapshot()

	if _field_dependencies.has(prop_name):
		call_deferred("_rebuild_ui")


func _register_field_dependencies() -> void:
	_field_dependencies.clear()
	for key in _template_keys:
		var config = _data_schema.get(key)
		if not (config is Dictionary):
			continue
		var variant = config.get(FIELD_VARIANT_CASES_KEY)
		if not (variant is Dictionary):
			continue
		var property_name: String = variant.get(FIELD_VARIANT_CASES_KEY, "")
		if property_name.is_empty():
			continue
		if not _field_dependencies.has(property_name):
			_field_dependencies[property_name] = []
		_field_dependencies[property_name].append(key)


func _normalize_item_for_template(item_data: Dictionary) -> void:
	if item_data == null:
		return
	for _i in range(NORMALIZE_ITERATIONS):
		var changed := false
		for key in _template_keys:
			var base_config = _data_schema.get(key)
			if not (base_config is Dictionary):
				continue
			var resolved_config = _resolve_field_settings(base_config, item_data)
			if not item_data.has(key) and resolved_config.has("default"):
				item_data[key] = resolved_config["default"]
				changed = true
			if resolved_config.has(FIELD_COERCE_KEY):
				var coerced = _coerce_value(
					item_data.get(key), str(resolved_config[FIELD_COERCE_KEY])
				)
				if item_data.get(key) != coerced:
					item_data[key] = coerced
					changed = true
		if not changed:
			break


func _resolve_field_settings(base_config: Dictionary, item_data: Dictionary) -> Dictionary:
	var resolved = base_config.duplicate(true)
	var cases = resolved.get(FIELD_VARIANT_CASES_KEY)
	if cases is Dictionary:
		for case: String in cases.keys():
			print(case)
	return resolved


func _normalize_options(source: Variant) -> Array:
	if source is Array:
		return (source as Array).duplicate(true)
	if source is PackedStringArray:
		return Array(source)
	if source is PackedInt32Array:
		var arr: Array = []
		for value in source:
			arr.append(value)
		return arr
	if source is String:
		return [source]
	if source == null:
		return []
	return [str(source)]


func _coerce_value(value: Variant, target_type: String) -> Variant:
	var lower_type := target_type.to_lower()
	match lower_type:
		"int":
			if value == null:
				return 0
			if value is int:
				return value
			if value is float:
				return int(round(value))
			if value is String:
				var trimmed: String = value.strip_edges()
				return 0 if trimmed.is_empty() else int(trimmed)
			return int(value)
		"float":
			if value == null:
				return 0.0
			if value is float:
				return value
			if value is int:
				return float(value)
			if value is String:
				var trimmed_f: String = value.strip_edges()
				return 0.0 if trimmed_f.is_empty() else float(trimmed_f)
			return float(value)
		"bool":
			if value is bool:
				return value
			if value is int:
				return value != 0
			if value is float:
				return not is_equal_approx(value, 0.0)
			if value is String:
				var lowered: String = value.strip_edges().to_lower()
				if lowered in ["true", "1", "yes", "on"]:
					return true
				if lowered in ["false", "0", "no", "off", ""]:
					return false
			return bool(value)
		"string":
			if value == null:
				return ""
			return value if value is String else str(value)
		_:
			return value


#func _create_editor_only_field(
#_prop_name: String, base_config: Dictionary, _item_data: Dictionary, item_index: int
#) -> Control:
#if base_config.get("type") != "button":
#return null
#var button = Button.new()
#button.text = base_config.get("button_text", "Edit")
#button.size_flags_horizontal = (
#Control.SIZE_EXPAND_FILL if base_config.get("expand", false) else 0
#)
#button.pressed.connect(base_config.get("action", func(_item_idx: int): return).bind(item_index))
#return button


func _has_dependent_fields(field_name: String) -> bool:
	var properties = _data_schema.get("properties", {})

	for prop_name in properties:
		var prop_config = properties[prop_name]

		if prop_config.has("condition"):
			if prop_config["condition"].get("property") == field_name:
				return true

		if prop_config.has("cases"):
			var variants = prop_config["cases"]
			if variants.get("property") == field_name:
				return true

	return false


func _on_duplicate_item(index: int) -> void:
	if index < 0 or index >= _list_items.size():
		return

	var item_to_duplicate = _list_items[index]
	var duplicated_item = item_to_duplicate.duplicate(true)

	if duplicated_item.has("protected"):
		duplicated_item["protected"] = false

	if duplicated_item.has("name"):
		duplicated_item["name"] = duplicated_item["name"] + " (Copy)"

	_list_items.insert(index + 1, duplicated_item)
	_rebuild_ui()
	_emit_snapshot()


func _on_delete_item(index: int) -> void:
	if index < 0 or index >= _list_items.size():
		return

	var item = _list_items[index]

	if item is Dictionary and item.get("protected", false):
		push_warning("Cannot delete protected item")
		return

	_list_items.remove_at(index)
	_rebuild_ui()
	_emit_snapshot()


func _emit_snapshot() -> void:
	var snapshot = _list_items.duplicate(true)
	emit_value_changed(snapshot)
	emit_value_committed(snapshot)


func validate() -> Dictionary:
	var all_errors: Array = []

	for i in range(_list_items.size()):
		var item = _list_items[i]
		if item is Dictionary:
			var validation_result = Schemas.validate(item, _data_schema)
			if not validation_result["valid"]:
				for error in validation_result["errors"]:
					all_errors.append("Item %d: %s" % [i + 1, error])

	var min_items = _data_schema.get("minItems", 0)
	if _list_items.size() < min_items:
		all_errors.append("At least %d items required" % min_items)

	if _data_schema.has("maxItems"):
		var max_items = _data_schema["maxItems"]
		if _list_items.size() > max_items:
			all_errors.append("Maximum %d items allowed" % max_items)

	return {"valid": all_errors.is_empty(), "errors": all_errors}
