class_name CharacterHistory extends PropertyHistory


## Character index.
var character_index: int = -1


func _init(index: int, graph: MonologueGraphEdit, path: NodePath,
			change_list: Array[PropertyChange]) -> void:
	super(graph, path, change_list)
	character_index = index


func change_properties() -> void:
	super.change_properties()
	_display_character()


func revert_properties() -> void:
	super.revert_properties()
	_display_character()


func set_property(node: Variant, property: String, value: Variant) -> void:
	super.set_property(node, property, value)
	graph_edit.speakers[character_index]["Character"][Util.to_key_name(property)] = value


func _display_character() -> void:
	var node = graph_edit.get_node(node_path)
	if node[changes[0].property].field.is_visible_in_tree():
		GlobalSignal.emit("reload_character_edit", [character_index])
	else:
		graph_edit.set_selected(graph_edit.get_root_node())
		GlobalSignal.emit("open_character_edit", [graph_edit, character_index])
		


func _hide_unrelated_windows() -> void:
	pass  # override
