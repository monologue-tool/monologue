extends EditorMenuButton

var graph_dict: Dictionary = {}


func _build_menu() -> void:
	var id: int = 0
	for category in NodeBucket.get_categories(false):
		var submenu: PopupMenu = add_submenu_row(category, _on_add_node)

		for node: GraphNodeDescriptor in NodeBucket.get_descriptors_by_category(category):
			var node_name: String = node.name
			var node_display_name: String = node.display_name
			submenu.add_item(node_display_name, id)
			graph_dict[id] = node_name
			id += 1


func _on_add_node(item_id: int) -> void:
	var node_name: String = graph_dict[item_id]
	EventBus.add_graph_node.emit(node_name)  # FIXME signal doesn't work
