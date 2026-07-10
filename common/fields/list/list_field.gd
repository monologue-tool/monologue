class_name ListField extends BaseListField

var _item_type: String = "text"
var _item_properties: Array[Property] = []
var _is_updating: bool = false


func _on_initialize() -> void:
	super._on_initialize()
	var property: Property = _binding.property if _binding else null
	if not property:
		Log.warning("ListField is not binded.")
		return

	_item_type = str(property.get_settings_value(PropertySettings.KEY_ITEM_TYPE, "text"))
	if not FieldBucket.get_field_descriptor(_item_type):
		Log.error("Can't find list item field type %s." % _item_type)


func _get_items() -> Array:
	return _item_properties


func set_value(value: Variant) -> void:
	if value is not Array:
		value = []

	_is_updating = true
	_item_properties.clear()
	for item_value: Variant in value:
		_item_properties.append(_create_item_property(item_value))
	_is_updating = false
	_rebuild_ui()


func get_value() -> Variant:
	var result: Array = []
	for item_property: Property in _item_properties:
		result.append(item_property.get_value())
	return result


func add_item() -> void:
	_item_properties.append(_create_item_property())
	emit_value_committed(get_value())
	_rebuild_ui()


func reorder_item(from_index: int, to_index: int) -> void:
	if from_index < 0 or from_index >= _item_properties.size():
		return
	if to_index < 0 or to_index >= _item_properties.size():
		return

	var item_property: Property = _item_properties.pop_at(from_index)
	_item_properties.insert(to_index, item_property)
	emit_value_committed(get_value())
	_rebuild_ui()


func _on_add_button() -> void:
	add_item()


func _on_delete_item(index: int) -> void:
	if not _is_valid_index(index):
		return
	_item_properties.remove_at(index)
	emit_value_committed(get_value())
	_rebuild_ui()


func _on_edit_item(_index: int) -> void:
	pass


func _on_duplicate_item(index: int) -> void:
	if not _is_valid_index(index):
		return
	var duplicated_value: Variant = _item_properties[index].get_value()
	_item_properties.insert(index + 1, _create_item_property(duplicated_value))
	emit_value_committed(get_value())
	_rebuild_ui()


func _rebuild_ui() -> void:
	if not is_node_ready():
		await ready

	_clear_container()

	for i in range(_item_properties.size()):
		if i in _hide_items:
			continue
		var item_property: Property = _item_properties[i]
		var container: PanelContainer = _create_item_container(not i % 2)
		items_container.add_child(container)

		var row: ListItemReorderRow = ListItemReorderRow.new()
		row.owner_field = self
		row.item_index = i
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(row)

		var drag_handle: ListItemDragHandle = ListItemDragHandle.new()
		drag_handle.owner_field = self
		drag_handle.item_index = i
		drag_handle.texture = preload("res://ui/assets/icons/drag_handle.svg")
		drag_handle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		drag_handle.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		drag_handle.custom_minimum_size = Vector2(24, 24)
		row.add_child(drag_handle)

		var item_field: Field = FieldBucket.create_field(_item_type)
		if not item_field:
			continue
		item_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_field.bind_field(item_property, null, true)
		row.add_child(item_field)

		var delete_button: Button = Button.new()
		delete_button.icon = preload("res://ui/assets/icons/cross.svg")
		delete_button.tooltip_text = "Delete item"
		delete_button.theme_type_variation = "ListItemIconButton"
		delete_button.pressed.connect(_on_delete_item.bind(i))
		row.add_child(delete_button)


func _create_item_property(value: Variant = null) -> Property:
	var descriptor: FieldDescriptor = FieldBucket.get_field_descriptor(_item_type)
	var default_value: Variant = value
	if default_value == null and descriptor:
		default_value = descriptor.default_value
	if default_value is Dictionary or default_value is Array:
		default_value = default_value.duplicate(true)
	var prop: Property = Property.new("item", default_value, _item_type, {
		"visible_in_inspector": false,
		"visible_in_graph": false,
		"expand": true,
	})
	prop.value_changed.connect(_on_item_property_changed.bind(prop))
	return prop


func _on_item_property_changed(_old_value: Variant, _new_value: Variant, _item_property: Property) -> void:
	if _is_updating:
		return
	emit_value_committed(get_value())


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < _item_properties.size()

func _populate_external_items() -> void:
	# TODO
	pass
