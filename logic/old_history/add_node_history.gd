## A special type of action history for handing creation and deletion
## of graph nodes.
class_name AddNodeHistory
extends MonologueHistory

## Reference to the graph edit node that this action should apply to.
var graph_edit: MonologueGraphEdit

## List of node references to be deleted on undo.
var deletion_nodes: Array[MonologueGraphNode]
## Dictionary of node name keys to node data dicts to be restored on redo.
var restoration_data: Dictionary
## Dictionary of inbound_connections to be restored on redo.
var inbound_connections: Dictionary
## Dictionary of out_connections to be restored on redo.
var outbound_connections: Dictionary

## The disconnected node name when this new node was created from picker.
var picker_from_node: String
## The disconnected port when this new node was created from picker.
var picker_from_port: int
## The node names that picker_from_node was connected to on to_port 0.
var picker_to_names: PackedStringArray


func _init(graph: MonologueGraphEdit, nodes: Array[MonologueGraphNode]):
	graph_edit = graph
	deletion_nodes = nodes

	# store node data (JSON values, connections, and options)
	for node in nodes:
		_record_connections(node)
		restoration_data[node.name] = node._to_dict()
		if "options" in node:
			restoration_data[node.name]["Options"] = node.options.value

	_undo_callback = _delete_callback_for_tracked_nodes
	_redo_callback = func() -> Array[MonologueGraphNode]:
		# the first key is the node type to re-add, it will handle
		# auxilliary creations (e.g. BridgeInNode)
		var node_name = restoration_data.keys().front()
		var node_type = restoration_data[node_name].get("$type")
		return graph_edit.add_node(node_type.trim_prefix("Node"), false)


func redo():
	_revert_picker(false)

	# track readded nodes and repopulate their data
	deletion_nodes = super.redo()
	# iterating this way, it will go through proper order in restoration_data
	for i in range(deletion_nodes.size()):
		var node_name = restoration_data.keys()[i]
		var node_data = restoration_data[node_name]

		# restore node name
		deletion_nodes[i].name = node_name

		# restore node data _from_dict()
		deletion_nodes[i]._from_dict(node_data)

		# for ChoiceNode, _from_dict() clears options and loads from JSON save
		# but it's okay, we can restore the changes in options from here
		var options = node_data.get("Options")
		if options:
			deletion_nodes[i].options.value = options
			deletion_nodes[i]._refresh(options)

		# restore graph node connections
		_restore_connections(node_name)

	return deletion_nodes


## This represents the undo callback after adding a node. It is defined this
## way so that it reads [member deletion_nodes] which will be updated on
## every redo, instead of bound arguments in the callback.
func _delete_callback_for_tracked_nodes():
	for i in deletion_nodes.size():
		var node = deletion_nodes[i]
		# restore node reference if it was broken by some other action
		# this can be caused by many undo/redo re-creating the node, thus our
		# reference here becomes outdated, but we can get it back by searching
		# the graph for its node name
		if not node:
			node = graph_edit.get_node(restoration_data.keys()[i])
		_record_connections(node)  # record connections first before freeing!!
		restoration_data[node.name] = graph_edit.free_graphnode(node)

	_revert_picker()
	return deletion_nodes


## Quick method to record all inbound and outbound connections of a given node.
func _record_connections(node: MonologueGraphNode):
	var name = node.name
	inbound_connections[name] = graph_edit.get_all_inbound_connections(name)
	outbound_connections[name] = graph_edit.get_all_outbound_connections(name)


## Restore graph connections to a given node name.
func _restore_connections(node_name: String):
	var inbound_links = inbound_connections.get(node_name)
	var outbound_links = outbound_connections.get(node_name)

	var connections = inbound_links + outbound_links
	for co in connections:
		graph_edit.propagate_connection(
			co.get("from_node"), co.get("from_port"), co.get("to_node"), co.get("to_port")
		)


## Reverts the severed connection from when this node was created by picker.
func _revert_picker(reconnect: bool = true):
	if picker_from_node:
		for to_name in picker_to_names:
			if reconnect:
				graph_edit.propagate_connection(picker_from_node, picker_from_port, to_name, 0)
			else:
				graph_edit.disconnect_node(picker_from_node, picker_from_port, to_name, 0)
