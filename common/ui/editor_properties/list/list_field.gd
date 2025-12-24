class_name ListField extends Field

var _list_items: Array[ListItemObject] = []
var _hide_items: Array[int] = []
var _data_schema: Dictionary = {}
var _layout: String = "default"
var _command_manager: CommandManager

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
	_list_items.clear()
	for property_data: Dictionary in value:
		var new_item: ListItemObject = ListItemObject.new(_data_schema, {}, _command_manager)
		new_item.list_field = self
		new_item._from_dict(property_data)
		_connect_item_observer(new_item)
		_list_items.append(new_item)

	_rebuild_ui()


func _connect_item_observer(item: ListItemObject) -> void:
	item.add_observer(_on_item_changed)


func _on_item_changed(_item: ListItemObject, prop_name: String) -> void:
	if _has_dependent_fields(prop_name):
		call_deferred("_rebuild_ui")

	_emit_snapshot()


func get_value() -> Variant:
	var result: Array = []
	for item: ListItemObject in _list_items:
		result.append(item._to_dict())
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

	_populate_items_container()


func _clear_items_container() -> void:
	for child in items_container.get_children():
		items_container.remove_child(child)
		child.queue_free()


func _populate_items_container() -> void:
	_clear_items_container()

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
	pass


func _on_duplicate_item(index: int) -> void:
	if not _is_valid_index(index):
		return
	# Duplicate from the raw store to avoid any editor wrappers
	var item_data: Dictionary = _list_items[index]._to_dict()
	var new_item: ListItemObject = ListItemObject.new(_data_schema, {}, _command_manager, {})
	new_item.list_field = self
	new_item._from_dict(item_data)
	_connect_item_observer(new_item)
	_list_items.insert(index + 1, new_item)
	_rebuild_ui()
	_emit_snapshot()


func _on_delete_item(index: int) -> void:
	if not _is_valid_index(index):
		return

	var item = _list_items[index]

	if item.is_protected():
		push_warning("Cannot delete protected item")
		return

	if index >= 0 and index < _list_items.size():
		_list_items.remove_at(index)
	_rebuild_ui()
	_emit_snapshot()


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < _list_items.size()


func _emit_snapshot() -> void:
	# Emit a deep copy of the raw store as the authoritative value
	emit_value_changed(get_value())
	emit_value_committed(get_value())


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
