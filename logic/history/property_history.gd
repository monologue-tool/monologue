class_name PropertyHistory
extends MonologueHistory


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
		node[change.property].propagate(change.after)
		node[change.property].value = change.after


func revert_properties() -> void:
	var node: Variant = graph_edit.get_node(node_path)
	for change in changes:
		node[change.property].propagate(change.before)
		node[change.property].value = change.before
