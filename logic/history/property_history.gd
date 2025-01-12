class_name PropertyHistory extends MonologueHistory


## Graph that owns the node whose properties have changed.
var graph_edit: MonologueGraphEdit
## Name of the graph node in the [member graph_edit].
var node_path: NodePath
## List of property changes to make on [member node_name].
var changes: Array[PropertyChange]


func _init(graph: MonologueGraphEdit, path: NodePath,
			change_list: Array[PropertyChange]) -> void:
	graph_edit = graph
	node_path = path
	changes = change_list
	
	_undo_callback = revert_properties
	_redo_callback = change_properties


func change_properties() -> void:
	var node: Variant = graph_edit.get_node(node_path)
	for change in changes:
		set_property(node, change.property, change.after)
	_hide_unrelated_windows()


func revert_properties() -> void:
	var node: Variant = graph_edit.get_node(node_path)
	for change in changes:
		set_property(node, change.property, change.before)
	_hide_unrelated_windows()


func set_property(node: Variant, property: String, value: Variant) -> void:
	node[property].propagate(value)
	node[property].value = value


func _hide_unrelated_windows() -> void:
	GlobalSignal.emit("close_character_edit")
