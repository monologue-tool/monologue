class_name ListField extends Field

const DISPLAY_PROPERTIES: Array = ["name", "description"]

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
	
	if not CollectionBucket.get_descriptor(collection):
		push_error("Can't find collection %s." % str(collection))
	
	_collection_name = collection


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
		new_item.set_meta("list_field", self)
		_connect_item_observer(new_item)
		_list_items.append(new_item)

	_rebuild_ui()


func _connect_item_observer(item: ListItem) -> void:
	item.add_observer(_on_item_changed)


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

	for child in items_container.get_children():
		if child.has_method("set_editable"):
			child.set_editable(is_editable)


func _clear_container() -> void:
	for item: Control in items_container.get_children():
		item.queue_free()


func _rebuild_ui() -> void:
	_clear_container()
	
	for item: ListItem in _list_items:
		var item_container = PanelContainer.new()
		item_container.theme_type_variation = "ListItemContainer"
		
		var main_vbox : VBoxContainer = _create_item_view()
		item_container.add_child(main_vbox)
		items_container.add_child(item_container)
		
		_populate_item_view(main_vbox, item)


func _create_item_view() -> VBoxContainer:
	var vbox: VBoxContainer = VBoxContainer.new()
	return vbox
	


func _populate_item_view(item_view: VBoxContainer, item: ListItem) -> void:
	var index = get_item_index(item)
	
	for prop: Property in item.get_properties():
		if not prop.name in DISPLAY_PROPERTIES:
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
	var field_config: Dictionary = prop.settings
	
	var title_container = HBoxContainer.new()
	title_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label = Label.new()
	label.text = Util.to_readable_name(field_name)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if field_config.has("tooltip"):
		label.tooltip_text = field_config["tooltip"]

	title_container.add_child(label)
	return title_container


func _get_or_create_header_container(content: Control) -> HBoxContainer:
	if content.get_child_count() == 0:
		return HBoxContainer.new()

	var first_child = content.get_child(0)
	if not first_child is BoxContainer or first_child.get_child_count() == 0:
		return HBoxContainer.new()

	var header_candidate = first_child.get_child(0)
	if header_candidate is HBoxContainer:
		return header_candidate

	return HBoxContainer.new()


func _make_item_header(
	content: Control,
	index: int,
	item: ListItem,
) -> HBoxContainer:
	var header = _get_or_create_header_container(content)
	var is_protected = item.get_property_value("protected") == true
	var actions = ["edit", "duplicate", "delete"] if not is_protected else ["edit"]
	var icons: Dictionary = {
		"delete": preload("res://ui/assets/icons/trash.svg"),
		"edit": preload("res://ui/assets/icons/pen.svg"),
		"duplicate": preload("res://ui/assets/icons/copy.png")
	}
	
	for action: String in actions:
		_add_button(
			header,
			index,
			action,
			action.capitalize() + " item",
			icons[action],
		)

	return header

func _add_button(
	header: HBoxContainer,
	index: int,
	action_name: String,
	tooltip: String,
	icon: Texture2D
) -> void:
	var button = Button.new()
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
		new_item.set_meta("list_field", self)
		# make sure name is valid
		var name_prop = new_item.get_property("name")
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

	var item = _list_items[index]

	if item.get_property_value("protected") == true:
		push_warning("Cannot delete protected item")
		return

	if index >= 0 and index < _list_items.size():
		_list_items.remove_at(index)
	_rebuild_ui()
	_emit_snapshot()


func _on_edit_item(index: int) -> void:
	var item: ListItem = _list_items[index]
	EventBus.request_object_inspection.emit(item)


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < _list_items.size()


func _emit_snapshot() -> void:
	emit_value_changed(get_value())
	emit_value_committed(get_value())


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
