@abstract
class_name BaseListField extends Field

var _hide_items: Array[int] = []
var _command_manager: CommandManager

@onready var items_container: VBoxContainer = %ItemsContainer
@onready var add_button: Button = %AddButton
## The row naming which item the list falls back to. Only the collection field's scene
## carries one, so both are null for a plain list.
@onready var default_container: Control = get_node_or_null("DefaultContainer")
@onready var default_option: OptionButton = get_node_or_null("%DefaultOptionButton")


func _ready() -> void:
	super._ready()
	_command_manager = CommandManager.new()
	if add_button and not add_button.pressed.is_connected(_on_add_button):
		add_button.pressed.connect(_on_add_button)
	if default_option and not default_option.item_selected.is_connected(set_default_item):
		default_option.item_selected.connect(set_default_item)
	# Stays out of the way until there is a list behind it to name.
	if default_container:
		default_container.hide()


func get_items() -> Array:
	if not _binding or not _binding.owner:
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
	_sync_default_row()


func set_editable(is_editable: bool) -> void:
	if not is_node_ready():
		await ready

	if add_button:
		add_button.disabled = not is_editable

	if is_instance_valid(default_option):
		default_option.disabled = not is_editable

	for child: Node in items_container.get_children():
		if child.has_method("set_editable"):
			child.call("set_editable", is_editable)


func get_item_index(item: CollectionItem) -> int:
	return get_items().find(item)


## Whether the list names one of its items as the one to fall back to. Only collections
## whose items declare the flag do, so plain lists never do.
func supports_default_item() -> bool:
	return false


## Makes the item at [param index] the one the list falls back to. No-op by default.
func set_default_item(_index: int) -> void:
	pass


## Refills the dropdown naming the fallback item. The row is hidden while there is
## nothing to choose between, and for collections that have no fallback at all.
func _sync_default_row() -> void:
	if not is_instance_valid(default_option):
		return

	var items: Array = get_items()
	if is_instance_valid(default_container):
		default_container.visible = supports_default_item() and not items.is_empty()

	default_option.clear()
	if not supports_default_item():
		return

	var selected: int = 0
	for index: int in items.size():
		var item: CollectionItem = items[index]
		default_option.add_item(_describe_item(item, index))
		if item.is_default_item():
			selected = index

	if default_option.item_count > 0:
		default_option.selected = selected


## How one item reads in the dropdown: whatever its preview property holds, or its type
## and position when that is empty.
func _describe_item(item: CollectionItem, index: int) -> String:
	var project: MonologueProject = ProjectManager.current_project
	var label: String = Util.to_label(
		item.get_property_value(item.get_preview_property_names()[0]),
		project.active_language_code if project else ""
	)
	if not label.is_empty():
		return label
	return "%s %d" % [Util.to_readable_name(item.get_type()), index + 1]


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
