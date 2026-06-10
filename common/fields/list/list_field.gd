class_name ListField extends Field

var _hide_items: Array[int] = []
var _collection_name: String = ""
var _command_manager: CommandManager

@onready var items_container: VBoxContainer = %ItemsContainer


func _ready() -> void:
	super._ready()
	_command_manager = CommandManager.new()

func _on_initialize() -> void:
	super._on_initialize()
	var property: Property = _binding.property if _binding else null
	if not property:
		Log.warning("ListField is not binded.")
	
	var collection: Variant = property.get_settings_value("collection")
	if not collection or  not CollectionBucket.get_descriptor(str(collection)):
		Log.error("Can't find collection %s." % str(collection))
		return
	_collection_name = collection

	if not property.connection_changed.is_connected(_on_connection_changed):
		property.connection_changed.connect(_on_connection_changed)


func _get_children() -> Array:
	if not _binding:
		return []
	return _binding.owner.get_property_children(_binding.property.name)


func hide_item(idx: int) -> void:
	_hide_items.append(idx)
	_rebuild_ui()


func show_all_items() -> void:
	_hide_items.clear()
	_rebuild_ui()


func set_value(value: Variant) -> void:
	if value is not Array:
		value = []
	
	var outdated_childrens: Array = _get_children().duplicate()
	for item_data: Dictionary in value:
		if item_data is not Dictionary:
			continue
		
		var child_found: bool = false
		for child: ListItem in outdated_childrens:
			var dict_match := false
			var item_id: Variant = item_data.get("id", {}).get("value") if item_data.has("id") else null
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
		
		# If there is no ListItem for this item, we create one.
		if not child_found:
			var item: ListItem = _create_new_list_item(item_data)
			_binding.owner.add_property_children(_binding.property.name, item)

	
	for child: ListItem in outdated_childrens:
		_binding.owner.remove_property_children(_binding.property.name, child)
	
	for child: ListItem in _get_children():
		if child.property_changed.is_connected(_on_item_property_changed):
			continue
		
		child.property_changed.connect(_on_item_property_changed.bind(child))
	
	for i in range(value.size()):
		var item_data: Dictionary = value[i]
		for child: ListItem in _get_children():
			if child._to_dict() == item_data:
				_binding.owner.move_property_child(_binding.property.name, child, i)
				break
	
	_rebuild_ui()


func get_value() -> Variant:
	var result: Array = []
	for item: InspectableObject in _get_children():
		result.append(item._to_dict())
	return result


func _create_new_list_item(from_data: Dictionary = {}) -> ListItem:
	var item: ListItem = CollectionBucket.create_item(_collection_name, _binding.owner.history)
	item._from_dict(from_data)
	
	return item


func _clear_container() -> void:
	for item: Control in items_container.get_children():
		items_container.remove_child(item)
		item.queue_free()


func _rebuild_ui() -> void:
	if not is_node_ready():
		await ready
	
	_clear_container()
	
	var items: Array = _get_children()
	for item: ListItem in items:
		var item_idx: int = items.find(item)
		var container: PanelContainer = _create_item_container(not item_idx % 2)
		
		items_container.add_child(container)
		ListItemHelper.populate_item_view(self, container, item, item_idx)
	
	_populate_external_items()


func get_item_index(item: ListItem) -> int:
	return _get_children().find(item)


func set_editable(is_editable: bool) -> void:
	if not is_node_ready():
		await ready
	
	for child: Node in items_container.get_children():
		if child.has_method("set_editable"):
			child.call("set_editable", is_editable)


func _create_item_container(is_odd: bool = false) -> PanelContainer:
	var container: PanelContainer = PanelContainer.new()
	container.theme_type_variation = "ListItemOddPanel" if is_odd else "ListItemPanel"
	return container


func _on_item_property_changed(_property_name: String, _item: ListItem) -> void:
	# The undo/redo is handle by the ListItem it self.
	# We're just updating the value of the list property.
	_binding.property.value = get_value()


func _on_edit_item(index: int) -> void:
	var item: ListItem = _get_children()[index]
	EventBus.request_object_inspection.emit(item)


func _on_duplicate_item(index: int) -> void:
	var children: Array = _get_children()
	if not _is_valid_index(index):
		return
		
	var item_data: Dictionary = children[index]._to_dict()
	var new_item: ListItem = CollectionBucket.create_item(_collection_name, _binding.owner.history)
	new_item._from_dict(item_data)
	_make_item_unique(new_item)
	
	_binding.owner.add_property_children(_binding.property.name, new_item)
	emit_value_committed(get_value())


func _make_item_unique(item: ListItem) -> void:
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
	var item: ListItem = _get_children()[index]
	_binding.owner.remove_property_children(_binding.property.name, item)
	
	emit_value_committed(get_value())


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < _get_children().size()


func add_item() -> void:
	var new_item: ListItem = _create_new_list_item()
	_make_item_unique(new_item)
	_binding.owner.add_property_children(_binding.property.name, new_item)
	
	emit_value_committed(get_value())


func _value_exists_in_list(pname: String, pvalue: Variant) -> bool:
	for item: InspectableObject in _get_children():
		var prop: Property = item.get_property(pname)
		if prop and prop.value == pvalue:
			return true
	return false


func _on_connection_changed() -> void:
	_rebuild_ui()


func _populate_external_items() -> void:
	var externals: Array[Dictionary] = _binding.owner.get_external_list_items(_binding.property.name)
	
	for ext_data: Dictionary in externals:
		var item_idx: int = items_container.get_child_count()
		var container: PanelContainer = _create_item_container(not item_idx % 2)
		ListItemHelper.populate_external_item_view(container, ext_data.get("name", "<unknown>"))
		items_container.add_child(container)
