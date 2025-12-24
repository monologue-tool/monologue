class_name GraphNodeTree
extends Tree

@onready var create_btn: Button = %CreateButton
@onready var window: GraphNodePicker = $"../../.."

var _first_item_found: bool = false


func _ready() -> void:
	reload_tree()


func reload_tree() -> void:
	clear()
	_first_item_found = false
	var root := create_item()
	create_btn.disabled = true

	var categories: PackedStringArray = NodeBucket.get_categories()
	if categories.is_empty():
		_add_placeholder(root, "No nodes available")
		return

	for category in categories:
		var category_item := create_item(root)
		category_item.set_text(0, category)
		category_item.collapsed = true
		category_item.set_selectable(0, false)
		var descriptors: Array = NodeBucket.get_descriptors_by_category(category)
		for descriptor in descriptors:
			_create_descriptor_item(category_item, descriptor)

	deselect_all()


func _add_placeholder(parent: TreeItem, text: String) -> void:
	var placeholder := create_item(parent)
	placeholder.set_text(0, text)
	placeholder.set_selectable(0, false)


func _create_descriptor_item(parent: TreeItem, descriptor) -> void:
	var item := create_item(parent)
	item.set_text(0, descriptor.display_name)
	if descriptor.icon:
		item.set_icon(0, descriptor.icon)
	item.set_metadata(0, descriptor.name)


func _create() -> bool:
	var selected := get_selected()
	if selected == null:
		return false
	var descriptor_name = selected.get_metadata(0)
	if descriptor_name == null:
		return false
	GlobalSignal.emit("add_graph_node", [String(descriptor_name), window])
	deselect_all()
	return true


func create_selected_descriptor() -> bool:
	return _create()


func _on_item_activated() -> void:
	var item: TreeItem = get_selected()
	if item == null:
		return
	if item.get_child_count() > 0:
		item.collapsed = !item.collapsed
		return
	if _create():
		window.close()


func _on_item_selected() -> void:
	var item: TreeItem = get_selected()
	if item == null:
		create_btn.disabled = true
		return
	create_btn.disabled = item.get_metadata(0) == null


func _on_search_bar_text_changed(new_text: String) -> void:
	if not new_text.lstrip(" "):
		_recursive_show_item(get_root())
		return

	_first_item_found = false
	_recursive_item_match(new_text, get_root())


func _recursive_item_match(text: String, item: TreeItem) -> bool:
	var match_text: bool = false

	if item.get_child_count() > 0:
		for child in item.get_children():
			var child_match: bool = _recursive_item_match(text, child)
			if child_match:
				match_text = true
	elif item.get_text(0).containsn(text):
		match_text = true
		if not _first_item_found:
			item.select(0)
			_first_item_found = true

	item.visible = match_text
	if match_text:
		item.collapsed = false

	return match_text


func _recursive_show_item(item: TreeItem) -> void:
	item.visible = true
	if not get_root() == item:
		item.collapsed = true
	for child in item.get_children():
		_recursive_show_item(child)
