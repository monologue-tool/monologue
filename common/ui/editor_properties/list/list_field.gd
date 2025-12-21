class_name ListField extends Field

const FIELD_VARIANT_CASES_KEY := "cases"
const FIELD_VARIANT_DEFAULT_KEY := "_default"
const FIELD_COERCE_KEY := "coerce"
const FIELD_OPTIONS_KEY := "options"

var _list_items: Array[ListItemObject] = []
var _hide_items: Array[int] = []
var _data_schema: Dictionary = {}
var _layout: String = "default"
var _command_manager: CommandManager
# Raw immutable data store for list values (schema–friendly, wrapper–free)
var _data_store: Array[Dictionary] = []

@onready var items_container: VBoxContainer = %ItemsContainer


func _ready() -> void:
	super._ready()
	_command_manager = CommandManager.new()


func hide_item(idx: int) -> void:
	_hide_items.append(idx)
	_rebuild_ui()


func show_all_items() -> void:
	_hide_items.clear()
	_rebuild_ui()


func set_value(value: Variant) -> void:
	# Initialize the raw data store from incoming value (deep copy, wrapper–free)
	_data_store.clear()
	if value is Array:
		for item_data in value:
			if item_data is Dictionary:
				_data_store.append(item_data.duplicate(true))
	_list_items.clear()
	_rebuild_ui()


func _convert_array_to_items(array: Array) -> void:
	for item_data in array:
		var dict_data = item_data.duplicate(true) if item_data is Dictionary else {}
		var item = ListItemObject.new(_data_schema, dict_data, _command_manager)
		item.list_field = self
		_list_items.append(item)
		_connect_item_observer(item)


func _connect_item_observer(item: ListItemObject) -> void:
	item.add_observer(_on_item_changed)


func _on_item_changed(_item: ListItemObject, prop_name: String) -> void:
	# Persist change back into the raw data store
	var idx := get_item_index(_item)
	if idx >= 0 and idx < _data_store.size():
		var dict: Dictionary = _item.to_dictionary()
		dict.erase("$type")
		_data_store[idx] = dict
	# Rebuild UI if the changed property affects other fields
	if _has_dependent_fields(prop_name):
		call_deferred("_rebuild_ui")

	_emit_snapshot()


func get_value() -> Variant:
	# Return a deep copy of the raw data store
	var result: Array = []
	for d in _data_store:
		result.append(d.duplicate(true))
	return result


func get_item_index(item: ListItemObject) -> int:
	return _list_items.find(item)


func set_editable(is_editable: bool) -> void:
	if not is_instance_valid(items_container):
		return

	for child in items_container.get_children():
		if child.has_method("set_editable"):
			child.set_editable(is_editable)


func _on_initialize() -> void:
	super._on_initialize()

	if _binding and _binding.property:
		_initialize_from_property(_binding.property)

	if not is_node_ready():
		await ready

	_rebuild_ui()


func _initialize_from_property(property: Property) -> void:
	_data_schema = property.get_settings_value("data_schema", {})
	_layout = property.get_settings_value("layout", "default")


func _rebuild_ui() -> void:
	if not is_instance_valid(items_container):
		return

	_clear_items_container()
	_populate_items_container()


func _clear_items_container() -> void:
	for child in items_container.get_children():
		items_container.remove_child(child)
		child.queue_free()


func _populate_items_container() -> void:
	# Rebuild view-model items from the raw data store
	_list_items.clear()
	for raw in _data_store:
		var item_dict := raw.duplicate(true)
		var item = ListItemObject.new(_data_schema, item_dict, _command_manager)
		item.list_field = self
		_list_items.append(item)
		_connect_item_observer(item)

	for i in range(_list_items.size()):
		if i in _hide_items:
			continue
		var item_ui = _create_item_ui(i)
		if item_ui:
			items_container.add_child(item_ui)


func _create_item_ui(index: int) -> Control:
	var item = _list_items[index]

	var item_container = PanelContainer.new()
	item_container.theme_type_variation = "ListItemContainer"

	var main_vbox = VBoxContainer.new()
	item_container.add_child(main_vbox)

	var content = LayoutManager.create_layout(_data_schema, item, self, _layout)
	if content:
		main_vbox.add_child(content)

	return item_container


func _has_dependent_fields(field_name: String) -> bool:
	var properties = _data_schema.get("properties", {})

	for prop_name in properties:
		var prop_config = properties[prop_name]

		if _has_condition_dependency(prop_config, field_name):
			return true

		if _has_variant_dependency(prop_config, field_name):
			return true

	return false


func _has_condition_dependency(prop_config: Dictionary, field_name: String) -> bool:
	if not prop_config.has("condition"):
		return false

	return prop_config["condition"].get("property") == field_name


func _has_variant_dependency(prop_config: Dictionary, field_name: String) -> bool:
	if not prop_config.has("cases"):
		return false

	var variants = prop_config["cases"]
	return variants.get("property") == field_name


func _on_edit_item(index: int) -> void:
	print("Edit item at index: ", index)
	# TODO: Open edit dialog


func _on_duplicate_item(index: int) -> void:
	if not _is_valid_index(index):
		return
	# Duplicate from the raw store to avoid any editor wrappers
	var base: Dictionary = _data_store[index].duplicate(true)
	# Apply common duplication tweaks
	if base.has("name"):
		base["name"] = String(base["name"]) + " (Copy)"
	var schema_props: Dictionary = _data_schema.get("properties", {})
	if schema_props.has("id") and schema_props["id"].get("default") is Callable:
		var id_gen: Callable = schema_props["id"]["default"]
		base["id"] = id_gen.call()
	_data_store.insert(index + 1, base)
	_rebuild_ui()
	_emit_snapshot()


func _on_delete_item(index: int) -> void:
	if not _is_valid_index(index):
		return

	var item = _list_items[index]

	if item.is_protected():
		push_warning("Cannot delete protected item")
		return

	if index >= 0 and index < _data_store.size():
		_data_store.remove_at(index)
	_rebuild_ui()
	_emit_snapshot()


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < _list_items.size()


func _emit_snapshot() -> void:
	# Emit a deep copy of the raw store as the authoritative value
	var snapshot: Array = []
	for d in _data_store:
		snapshot.append(d.duplicate(true))
	emit_value_changed(snapshot)
	emit_value_committed(snapshot)


func undo() -> void:
	if _command_manager:
		_command_manager.undo()
		_rebuild_ui()


func redo() -> void:
	if _command_manager:
		_command_manager.redo()
		_rebuild_ui()


func can_undo() -> bool:
	return _command_manager and _command_manager.can_undo()


func can_redo() -> bool:
	return _command_manager and _command_manager.can_redo()


func validate() -> Dictionary:
	var all_errors: Array = []

	_validate_items(all_errors)
	_validate_item_count(all_errors)

	return {"valid": all_errors.is_empty(), "errors": all_errors}


func _validate_items(errors: Array) -> void:
	for i in range(_list_items.size()):
		var item = _list_items[i]
		_validate_single_item(item, i, errors)


func _validate_single_item(item: ListItemObject, index: int, errors: Array) -> void:
	var item_dict = item.to_dictionary()
	item_dict.erase("$type")
	var validation_result = Schemas.validate(item_dict, _data_schema)

	if not validation_result["valid"]:
		for error in validation_result["errors"]:
			errors.append("Item %d: %s" % [index + 1, error])


func _validate_item_count(errors: Array) -> void:
	var min_items = _data_schema.get("minItems", 0)
	if _list_items.size() < min_items:
		errors.append("At least %d items required" % min_items)

	if _data_schema.has("maxItems"):
		var max_items = _data_schema["maxItems"]
		if _list_items.size() > max_items:
			errors.append("Maximum %d items allowed" % max_items)
