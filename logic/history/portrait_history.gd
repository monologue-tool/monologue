class_name PortraitHistory extends CharacterHistory


## Portrait index.
var portrait_index: int = -1


func _init(_character_index: int, _portrait_index: int, graph: MonologueGraphEdit, path: NodePath,
			change_list: Array[PropertyChange]) -> void:
	super(_character_index, graph, path, change_list)
	portrait_index = _portrait_index


func change_properties() -> void:
	super.change_properties()
	_display_portrait()


func revert_properties() -> void:
	super.revert_properties()
	_display_portrait()


func set_property(_node: Variant, property: String, value: Variant) -> void:
	graph_edit.speakers[character_index]["Character"]["Portraits"][portrait_index][Util.to_key_name(property)] = value


func _display_portrait() -> void:
	var _node = graph_edit.get_node(node_path)
	#if node[changes[0].property].field.is_visible_in_tree():
		#GlobalSignal.emit("reload_character_edit", [character_index])
	#else:
		#graph_edit.set_selected(graph_edit.get_root_node())
		#GlobalSignal.emit("open_character_edit", [graph_edit, character_index])
