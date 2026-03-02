class_name NodeConnectionCommand extends Command

var graph_view: MonologueGraphEdit
var from_node_id: String
var to_node_id: String
var from_property_name: String
var to_property_name: String
var disconnect_node: bool


func _init(
	n_graph_view: MonologueGraphEdit,
	n_from_node_id: String,
	n_to_node_id: String,
	n_from_property_name: String,
	n_to_property_name: String,
	n_disconnect: bool = false
) -> void:
	graph_view = n_graph_view
	from_node_id = n_from_node_id
	to_node_id = n_to_node_id
	from_property_name = n_from_property_name
	to_property_name = n_to_property_name
	disconnect_node = n_disconnect


func execute() -> void:
	# Recalculate port indices in case they changed
	var from_port = graph_view.get_port_index_for_property(from_node_id, from_property_name)
	var to_port = graph_view.get_port_index_for_property(to_node_id, to_property_name)

	if disconnect_node:
		if graph_view.connection_manager:
			graph_view.connection_manager.unregister_connection(
				from_node_id, from_port, to_node_id, to_port
			)

		if from_port >= 0 and to_port >= 0:
			graph_view.disconnect_node(from_node_id, from_port, to_node_id, to_port)
	else:
		if graph_view.connection_manager:
			graph_view.connection_manager.register_connection_by_property(
				from_node_id, from_property_name, to_node_id, to_property_name
			)

		if from_port >= 0 and to_port >= 0:
			graph_view.connect_node(from_node_id, from_port, to_node_id, to_port)

	_notify_node_changes()


func undo() -> void:
	# Recalculate port indices in case they changed
	var from_port = graph_view.get_port_index_for_property(from_node_id, from_property_name)
	var to_port = graph_view.get_port_index_for_property(to_node_id, to_property_name)

	if not disconnect_node:
		if graph_view.connection_manager:
			graph_view.connection_manager.unregister_connection(
				from_node_id, from_port, to_node_id, to_port
			)

		if from_port >= 0 and to_port >= 0:
			graph_view.disconnect_node(from_node_id, from_port, to_node_id, to_port)
	else:
		if graph_view.connection_manager:
			graph_view.connection_manager.register_connection_by_property(
				from_node_id, from_property_name, to_node_id, to_property_name
			)

		if from_port >= 0 and to_port >= 0:
			graph_view.connect_node(from_node_id, from_port, to_node_id, to_port)

	_notify_node_changes()


func _notify_node_changes() -> void:
	var storyline: StorylineDocument = StorylineManager.get_storyline(graph_view.storyline_id)
	var from_nodes: Array = storyline.nodes.filter(
		func(n: InspectableNode) -> bool: return n.get_property_value("id") == from_node_id
	)
	var to_nodes: Array = storyline.nodes.filter(
		func(n: InspectableNode) -> bool: return n.get_property_value("id") == to_node_id
	)

	if not from_nodes.is_empty():
		var from_node: InspectableNode = from_nodes[0]
		from_node._notify_change(from_node_id)

	if not to_nodes.is_empty():
		var to_node: InspectableNode = to_nodes[0]
		to_node._notify_change(to_property_name)


func get_description() -> String:
	return (
		"Connect %s.%s to %s.%s" % [from_node_id, from_property_name, to_node_id, to_property_name]
	)
