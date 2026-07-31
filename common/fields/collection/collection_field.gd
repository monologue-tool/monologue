class_name CollectionField extends BaseListField

var _collection_name: String = ""


func _on_initialize() -> void:
	super._on_initialize()
	var property: Property = _binding.property if _binding else null
	if not property:
		Log.warning("CollectionField is not binded.")

	var collection: Variant = property.get_settings_value("collection")
	if not collection or not CollectionBucket.get_descriptor(str(collection)):
		Log.error("Can't find collection %s." % str(collection))
		return
	_collection_name = collection

	if not property.connection_changed.is_connected(_on_connection_changed):
		property.connection_changed.connect(_on_connection_changed)


func set_value(value: Variant) -> void:
	var need_rebuild: bool = true

	if value is not Array:
		value = []

	var outdated_childrens: Array = get_items().duplicate()
	for item_data: Dictionary in value:
		if item_data is not Dictionary:
			continue

		var child_found: bool = false
		for child: CollectionItem in outdated_childrens:
			var dict_match := false
			var item_id: Variant = (
				item_data.get("id", {}).get("value") if item_data.has("id") else null
			)
			var child_id: Variant = child.get_property_value("id")

			if item_id != null and child_id != null:
				dict_match = (item_id == child_id)
			else:
				dict_match = (item_data == child._to_dict())

			if dict_match:
				child._from_dict(item_data)
				outdated_childrens.erase(child)
				child_found = true
				break

		if not child_found:
			var item: CollectionItem = _create_new_list_item(item_data)
			_binding.owner.add_property_children(_binding.property.name, item)

	for child: CollectionItem in outdated_childrens:
		_binding.owner.remove_property_children(_binding.property.name, child)

	for child: CollectionItem in get_items():
		if child.property_changed.is_connected(_on_item_property_changed):
			continue

		child.property_changed.connect(_on_item_property_changed.bind(child))

	for i in range(value.size()):
		var item_data: Dictionary = value[i]
		for child: CollectionItem in get_items():
			if child._to_dict() == item_data:
				_binding.owner.move_property_child(_binding.property.name, child, i)
				break

	if need_rebuild:
		_rebuild_ui()


func get_value() -> Variant:
	var result: Array = []
	for item: InspectableObject in get_items():
		result.append(item._to_dict())
	return result


func _create_new_list_item(from_data: Dictionary = {}) -> CollectionItem:
	var item: CollectionItem = CollectionBucket.create_item(
		_collection_name, _binding.owner.history
	)
	item._from_dict(from_data)

	return item


func _on_item_property_changed(_property_name: String, _item: CollectionItem) -> void:
	# The undo/redo is handle by the CollectionItem it self.
	# We're just updating the value of the list property.
	_binding.property.value = get_value()


func _on_add_button() -> void:
	add_item()


func _on_edit_item(index: int) -> void:
	var item: CollectionItem = get_items()[index]
	EventBus.request_object_inspection.emit(item)


func _on_duplicate_item(index: int) -> void:
	var children: Array = get_items()
	if not _is_valid_index(index):
		return

	var item_data: Dictionary = children[index]._to_dict()
	var new_item: CollectionItem = CollectionBucket.create_item(
		_collection_name, _binding.owner.history
	)
	new_item._from_dict(item_data)
	_make_item_unique(new_item)

	_binding.owner.add_property_children(_binding.property.name, new_item)
	emit_value_committed(get_value())


func _make_item_unique(item: CollectionItem) -> void:
	for prop: Property in item.get_properties():
		if not prop.get_settings_value(PropertySettings.KEY_UNIQUE, false):
			continue

		if prop.name == "id":
			prop.value = IDGen.generate(InspectableObject.ID_LENGTH)

		var base_val: String = str(prop.value)
		var regex := RegEx.new()
		regex.compile(r"^(.*?)(\d+)$")
		var result := regex.search(base_val)
		var name_base: String = base_val + " "
		var attempt: int = 1

		if result:
			name_base = result.get_string(1)
			attempt = int(result.get_string(2)) + 1

		while _value_exists_in_list(prop.name, prop.value):
			if prop.name == "id":
				prop.value = IDGen.generate(InspectableObject.ID_LENGTH)
			else:
				prop.value = "%s%d" % [name_base, attempt]
				attempt += 1


func _on_delete_item(index: int) -> void:
	var item: CollectionItem = get_items()[index]
	_binding.owner.remove_property_children(_binding.property.name, item)

	emit_value_committed(get_value())
	_rebuild_ui()


func reorder_item(from_index: int, to_index: int) -> void:
	var children: Array = get_items()
	if from_index < 0 or from_index >= children.size():
		return
	if to_index < 0 or to_index >= children.size():
		return

	_binding.owner.move_property_child(_binding.property.name, children[from_index], to_index)
	emit_value_committed(get_value())
	_rebuild_ui()


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < get_items().size()


func add_item() -> void:
	var new_item: CollectionItem = _create_new_list_item()
	_make_item_unique(new_item)
	_binding.owner.add_property_children(_binding.property.name, new_item)

	emit_value_committed(get_value())
	_rebuild_ui()


func _value_exists_in_list(pname: String, pvalue: Variant) -> bool:
	for item: InspectableObject in get_items():
		var prop: Property = item.get_property(pname)
		if prop and prop.value == pvalue:
			return true
	return false


func _on_connection_changed() -> void:
	_rebuild_ui()


func _populate_external_items() -> void:
	var externals: Array[Dictionary] = _binding.owner.get_external_list_items(
		_binding.property.name
	)

	for ext_data: Dictionary in externals:
		var item_idx: int = items_container.get_child_count()
		var container: PanelContainer = _create_item_container(not item_idx % 2)
		CollectionItemHelper.populate_external_item_view(
			container, ext_data.get("name", "<unknown>")
		)
		items_container.add_child(container)
