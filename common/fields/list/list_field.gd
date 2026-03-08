class_name ListField extends Field

var _list_items: Array[ListItem] = []
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
		push_error("ListField is not binded.")
	
	var collection: Variant = property.get_settings_value("collection")
	if not collection:
		push_error("Collection is missing.")
		return
	
	if not CollectionBucket.get_descriptor(str(collection)):
		push_error("Can't find collection %s." % str(collection))
	
	_collection_name = collection

	# Listen for connection changes to rebuild imported items
	if not property.connection_changed.is_connected(_on_connection_changed):
		property.connection_changed.connect(_on_connection_changed)


func hide_item(idx: int) -> void:
	_hide_items.append(idx)
	_rebuild_ui()


func show_all_items() -> void:
	_hide_items.clear()
	_rebuild_ui()


func set_value(value: Variant) -> void:
	if not is_node_ready():
		await ready
		
	_list_items.clear()
	for property_data: Dictionary in value:
		var new_item: ListItem = CollectionBucket.create_item(_collection_name, _command_manager)
		if not new_item:
			continue
		
		new_item._from_dict(property_data)
		new_item.set_meta("list_siblings", _list_items)
		_connect_item_observer(new_item)
		_list_items.append(new_item)

	_rebuild_ui()


func _connect_item_observer(item: ListItem) -> void:
	item.add_observer(_on_item_changed)
	# Store the information needed to push a snapshot even after this ListField node is freed
	# WeakRef lets callers detect the freed state cheaply without keeping it alive.
	item.set_meta("_list_field_ref", weakref(self))
	if _binding:
		item.set_meta("_parent_owner", _binding.owner)       # InspectableObject (Resource)
		item.set_meta("_parent_prop_name", _binding.property.name)


func _on_item_changed(_item: ListItem, _prop_name: String) -> void:
	_emit_snapshot()


func get_value() -> Variant:
	var result: Array = []
	for item: ListItem in _list_items:
		result.append(item._to_dict())
	return result


func get_item_index(item: ListItem) -> int:
	return _list_items.find(item)


func set_editable(is_editable: bool) -> void:
	if not is_instance_valid(items_container):
		return

	for child: Node in items_container.get_children():
		if child.has_method("set_editable"):
			child.call("set_editable", is_editable)


func _clear_container() -> void:
	for item: Control in items_container.get_children():
		item.queue_free()


func _rebuild_ui() -> void:
	_clear_container()
	
	for item: ListItem in _list_items:
		var item_container: PanelContainer = PanelContainer.new()
		item_container.theme_type_variation = "ListItemContainer"
		
		var main_vbox : VBoxContainer = _create_item_view()
		item_container.add_child(main_vbox)
		items_container.add_child(item_container)
		
		_populate_item_view(main_vbox, item)

	# Show external (imported) items at the end
	_populate_external_items()


func _create_item_view() -> VBoxContainer:
	var vbox: VBoxContainer = VBoxContainer.new()
	return vbox
	


func _populate_item_view(item_view: VBoxContainer, item: ListItem) -> void:
	var index: int = get_item_index(item)
	
	for prop: Property in item.get_properties():
		if not prop.name in item.get_preview_property_names():
			continue
			
		var field_container: VBoxContainer = VBoxContainer.new()
		var field: Field = FieldBucket.create_field(prop.type)
		var field_title: HBoxContainer = _create_field_title(prop)
		
		field_container.add_child(field_title)
		field_container.add_child(field)
		item_view.add_child(field_container)
		
		prop.bind_field(field, item)
		
	_make_item_header(item_view, index, item)


func _create_field_title(prop: Property) -> HBoxContainer:
	var field_name: String = prop.name
	var field_config: Dictionary = prop.get_settings()
	
	var title_container: HBoxContainer = HBoxContainer.new()
	title_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = Util.to_readable_name(field_name)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if field_config.has("tooltip"):
		label.tooltip_text = field_config["tooltip"]

	title_container.add_child(label)
	return title_container


func _get_or_create_header_container(content: Control) -> HBoxContainer:
	if content.get_child_count() == 0:
		return HBoxContainer.new()

	var first_child: Node = content.get_child(0)
	if not first_child is BoxContainer or first_child.get_child_count() == 0:
		return HBoxContainer.new()

	var header_candidate: Node = first_child.get_child(0)
	if header_candidate is HBoxContainer:
		return header_candidate

	return HBoxContainer.new()


func _make_item_header(
	content: Control,
	index: int,
	item: ListItem,
) -> HBoxContainer:
	var header: HBoxContainer = _get_or_create_header_container(content)
	var is_protected: bool = item.get_property_value("protected") == true
	var actions: Array = ["edit", "duplicate", "delete"] if not is_protected else ["edit"]
	var icons: Dictionary = {
		"delete": preload("res://ui/assets/icons/trash.svg"),
		"edit": preload("res://ui/assets/icons/pen.svg"),
		"duplicate": preload("res://ui/assets/icons/copy.png")
	}

	for action: String in actions:
		var icon: Texture2D = icons[action]
		_add_button(
			header,
			index,
			action,
			action.capitalize() + " item",
			icon,
		)

	return header

func _add_button(
	header: HBoxContainer,
	index: int,
	action_name: String,
	tooltip: String,
	icon: Texture2D
) -> void:
	var button: Button = Button.new()
	button.icon = icon
	button.tooltip_text = tooltip
	button.pressed.connect(call.bind("_on_%s_item" % action_name, index))
	header.add_child(button)



func _on_duplicate_item(index: int) -> void:
	if not _is_valid_index(index):
		return
	var item_data: Dictionary = _list_items[index]._to_dict()
	var new_item: ListItem = CollectionBucket.create_item(_collection_name, _command_manager)
	if new_item:
		new_item._from_dict(item_data)
		new_item.set_meta("list_siblings", _list_items)
		# make sure name is valid
		var name_prop: Property = new_item.get_property("name")
		if name_prop:
			name_prop.value = str(name_prop.value) + " (Copy)"
		
		# Since we don't have make_all_values_unique anymore on standard items unless it's in logic,
		# we'll just insert it.
		_connect_item_observer(new_item)
		_list_items.insert(index + 1, new_item)
		_rebuild_ui()
		_emit_snapshot()


func _on_delete_item(index: int) -> void:
	if not _is_valid_index(index):
		return

	var item: ListItem = _list_items[index]

	if item.get_property_value("protected") == true:
		push_warning("Cannot delete protected item")
		return

	if index >= 0 and index < _list_items.size():
		_list_items.remove_at(index)
	_rebuild_ui()
	_emit_snapshot()


func _on_edit_item(index: int) -> void:
	if not _binding or not _binding.property:
		return
	EventBus.request_child_inspection.emit(_binding.owner, _binding.property.name, index)


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < _list_items.size()


func add_item() -> void:
	if not _binding or not _binding.owner:
		return
	var item_object: ListItem = CollectionBucket.create_item(_collection_name, _command_manager)
	if not item_object:
		return
	for prop: Property in item_object.get_properties():
		if not prop.get_settings_value(PropertySettings.KEY_UNIQUE, false):
			continue
		var base_val: String = str(prop.value)
		var attempt: int = 1
		while _value_exists_in_list(prop.name, prop.value):
			prop.value = "%s %d" % [base_val, attempt]
			attempt += 1
	var prop_value: Variant = _binding.property.get_value()
	var new_item_list: Array = []
	if prop_value is Array:
		var arr: Array = prop_value
		new_item_list = arr.duplicate(true)
	new_item_list.append(item_object._to_dict())
	_binding.owner.set_property_value(_binding.property.name, new_item_list)


func _value_exists_in_list(pname: String, pvalue: Variant) -> bool:
	for item: ListItem in _list_items:
		var prop: Property = item.get_property(pname)
		if prop and prop.value == pvalue:
			return true
	return false


func _emit_snapshot() -> void:
	is_emitting_snapshot = true
	emit_value_changed(get_value())
	emit_value_committed(get_value())
	is_emitting_snapshot = false


func _on_connection_changed() -> void:
	_rebuild_ui()


func _populate_external_items() -> void:
	if not _binding or not _binding.owner:
		return
	var externals: Array[Dictionary] = _binding.owner.get_external_list_items(_binding.property.name)
	if externals.is_empty():
		return

	for ext_data: Dictionary in externals:
		var item_container: PanelContainer = PanelContainer.new()
		item_container.theme_type_variation = "ListItemContainer"
		item_container.modulate = Color(1, 1, 1, 0.6)

		var main_vbox: VBoxContainer = VBoxContainer.new()
		item_container.add_child(main_vbox)

		var header: HBoxContainer = HBoxContainer.new()
		var ext_label: Label = Label.new()
		ext_label.text = ext_data.get("name", "External")
		ext_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(ext_label)

		var badge: Label = Label.new()
		badge.text = "(imported)"
		badge.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		header.add_child(badge)

		main_vbox.add_child(header)

		# Show text preview if available
		var text_val: Variant = ext_data.get("text", "")
		if text_val is Dictionary:
			var text_dict: Dictionary = text_val
			text_val = text_dict.get("value", "")
		if not str(text_val).is_empty():
			var text_label: Label = Label.new()
			text_label.text = str(text_val)
			text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			main_vbox.add_child(text_label)

		items_container.add_child(item_container)


func undo() -> void:
	if not _command_manager:
		return
		
	_command_manager.undo()
	_rebuild_ui()


func redo() -> void:
	if not _command_manager:
		return
	
	_command_manager.redo()
	_rebuild_ui()
