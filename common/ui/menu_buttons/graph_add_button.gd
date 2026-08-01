extends EditorMenuButton

var graph_dict: Dictionary = {}


func _build_menu() -> void:
	var registry: MonologueRegistry = MonologueRegistry.get_instance()
	var id: int = 0
	for category: String in registry.list_categories(MonologueObjectType.NODE):
		var submenu: PopupMenu = add_submenu_row(category, _on_add_node)

		for node: MonologueIndexer in registry.list_by_category(MonologueObjectType.NODE, category):
			submenu.add_item(node.get_display_name(), id)
			graph_dict[id] = node.name
			id += 1


func _on_add_node(item_id: int) -> void:
	var node_name: String = graph_dict[item_id]
	EventBus.add_graph_node.emit(node_name)  # FIXME signal doesn't work
