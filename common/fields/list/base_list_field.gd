@abstract
class_name BaseListField extends Field

var _hide_items: Array[int] = []
var _command_manager: CommandManager

@onready var items_container: VBoxContainer = %ItemsContainer
@onready var add_button: Button = %AddButton


func _ready() -> void:
	super._ready()
	_command_manager = CommandManager.new()
	if add_button and not add_button.pressed.is_connected(_on_add_button):
		add_button.pressed.connect(_on_add_button)


func get_items() -> Array:
	if not _binding:
		return []
	return _binding.owner.get_property_children(_binding.property.name)


func hide_item(idx: int) -> void:
	if not idx in _hide_items:
		_hide_items.append(idx)
	_rebuild_ui()


func show_all_items() -> void:
	_hide_items.clear()
	_rebuild_ui()


func _clear_container() -> void:
	for item: Control in items_container.get_children():
		items_container.remove_child(item)
		item.queue_free()


func _rebuild_ui() -> void:
	if not is_node_ready():
		await ready

	_clear_container()

	var items: Array = get_items()
	for item: CollectionItem in items:
		var item_idx: int = items.find(item)
		if item_idx in _hide_items:
			continue
		var container: PanelContainer = _create_item_container(not item_idx % 2)
		items_container.add_child(container)
		CollectionItemHelper.populate_item_view(self, container, item, item_idx)

	_populate_external_items()


func set_editable(is_editable: bool) -> void:
	if not is_node_ready():
		await ready

	for child: Node in items_container.get_children():
		if child.has_method("set_editable"):
			child.call("set_editable", is_editable)


func get_item_index(item: CollectionItem) -> int:
	return get_items().find(item)


func get_list_item_controls(exclude_externals: bool = false) -> Array[Node]:
	var items: Array[Node] = items_container.get_children()
	for item: Node in items:
		var row: ListItemReorderRow = item.get_child(0)
		if row.external and exclude_externals:
			items.erase(item)
	
	return items


func _create_item_container(is_odd: bool = false) -> PanelContainer:
	var container: PanelContainer = PanelContainer.new()
	container.theme_type_variation = "ListItemOddPanel" if is_odd else "ListItemPanel"
	return container


@abstract func reorder_item(_from_index: int, _to_index: int) -> void
@abstract func _on_add_button() -> void
@abstract func _on_edit_item(_index: int) -> void
@abstract func _on_duplicate_item(_index: int) -> void
@abstract func _on_delete_item(_index: int) -> void
@abstract func _populate_external_items() -> void
