extends Field

const FIELD_VARIANTS_KEY := "field_variants"
const FIELD_VARIANT_PROPERTY_KEY := "property"
const FIELD_VARIANT_CASES_KEY := "cases"
const FIELD_VARIANT_DEFAULT_KEY := "_default"
const FIELD_COERCE_KEY := "coerce"
const FIELD_OPTIONS_KEY := "options"
const NORMALIZE_ITERATIONS := 4

var _list_items: Array = []
var _item_template: Dictionary = {}
var _template_keys: Array = []
var _field_dependencies: Dictionary = {}

@onready var items_container: VBoxContainer = %ItemsContainer


func _ready() -> void:
	super._ready()


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
		_item_template = property.settings.get("item_template", {})
		_template_keys = _item_template.keys()
		_register_field_dependencies()

	if not is_node_ready():
		await ready
	_rebuild_ui()


func _rebuild_ui() -> void:
	if not is_instance_valid(items_container):
		return

	for child in items_container.get_children():
		child.queue_free()

	for i in range(_list_items.size()):
		var item_ui = _create_item_ui(i)
		if item_ui:
			items_container.add_child(item_ui)


func _create_item_ui(index: int) -> Control:
	var item_panel = PanelContainer.new()
	item_panel.theme_type_variation = "ListItemContainer"

	var vbox = VBoxContainer.new()
	item_panel.add_child(vbox)

	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)

	var label = Label.new()
	label.theme_type_variation = "NoteLabel"
	label.text = "Item " + str(index + 1)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(label)

	var delete_button = Button.new()
	delete_button.icon = preload("res://ui/assets/icons/trash.svg")
	delete_button.tooltip_text = "Remove item"
	delete_button.pressed.connect(_on_delete_item.bind(index))
	header_hbox.add_child(delete_button)

	var item_data = _list_items[index]
	if not item_data is Dictionary:
		item_data = {}
		_list_items[index] = item_data

	_normalize_item_for_template(item_data)

	for prop_name in _template_keys:
		var base_config = _item_template.get(prop_name)
		if base_config == null:
			continue
		var field_control = _create_property_field(prop_name, base_config, item_data, index)
		if field_control:
			vbox.add_child(field_control)

	return item_panel


func _create_property_field(
	prop_name: String, base_config: Dictionary, item_data: Dictionary, item_index: int
) -> Control:
	var config_copy := base_config.duplicate(true)
	if config_copy.get("editor_only", false):
		return _create_editor_only_field(prop_name, config_copy, item_data, item_index)

	var resolved_config := _resolve_field_settings(config_copy, item_data)
	var field_type: String = resolved_config.get("type", "text")

	var container = HBoxContainer.new()

	var prop_label = Label.new()
	prop_label.text = Util.to_readable_name(prop_name)
	prop_label.custom_minimum_size.x = 100
	container.add_child(prop_label)

	var field: Field = FieldBucket.create_field(field_type)
	if not field:
		var warn_label = Label.new()
		warn_label.theme_type_variation = "WarnLabel"
		warn_label.text = "Unknown field type: " + field_type
		container.add_child(warn_label)
		return container

	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_configure_field(field, resolved_config)
	container.add_child(field)

	var current_value = item_data.get(prop_name, resolved_config.get("default", null))
	item_data[prop_name] = current_value
	field.set_value.call_deferred(current_value)

	var captured_base := config_copy.duplicate(true)
	field.value_committed.connect(
		func(new_value): _on_item_property_changed(item_index, prop_name, new_value, captured_base)
	)

	return container


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


func _on_delete_item(index: int) -> void:
	if index < 0 or index >= _list_items.size():
		return
	_list_items.remove_at(index)
	_rebuild_ui()
	_emit_snapshot()


func _emit_snapshot() -> void:
	var snapshot := _list_items.duplicate(true)
	emit_value_changed(snapshot)
	emit_value_committed(snapshot)


func _register_field_dependencies() -> void:
	_field_dependencies.clear()
	for key in _template_keys:
		var config = _item_template.get(key)
		if not (config is Dictionary):
			continue
		var variant = config.get(FIELD_VARIANTS_KEY)
		if not (variant is Dictionary):
			continue
		var property_name: String = variant.get(FIELD_VARIANT_PROPERTY_KEY, "")
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
			var base_config = _item_template.get(key)
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
	var variant = resolved.get(FIELD_VARIANTS_KEY)
	if variant is Dictionary:
		var property_name: String = variant.get(FIELD_VARIANT_PROPERTY_KEY, "")
		if not property_name.is_empty():
			var cases: Dictionary = variant.get(FIELD_VARIANT_CASES_KEY, {})
			var lookup_value = item_data.get(property_name)
			if not cases.has(lookup_value):
				lookup_value = cases.get(FIELD_VARIANT_DEFAULT_KEY, lookup_value)
			if cases.has(lookup_value):
				var override = cases.get(lookup_value)
				if override is Dictionary:
					resolved.merge(override, true)
	return resolved


func _configure_field(field: Field, config: Dictionary) -> void:
	if config.has(FIELD_OPTIONS_KEY) and field.has_method("set_static_options"):
		field.set_static_options(_normalize_options(config[FIELD_OPTIONS_KEY]))
	if field.has_method("apply_config"):
		field.apply_config(config)
	elif config.has("placeholder") and field.has_method("set_placeholder"):
		field.set_placeholder(config.get("placeholder", ""))


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


func _create_editor_only_field(
	_prop_name: String, base_config: Dictionary, _item_data: Dictionary, item_index: int
) -> Control:
	if base_config.get("type") != "button":
		return null
	var button = Button.new()
	button.text = base_config.get("button_text", "Edit")
	button.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL if base_config.get("expand", false) else 0
	)
	button.pressed.connect(base_config.get("action", func(_item_idx: int): return).bind(item_index))
	return button
