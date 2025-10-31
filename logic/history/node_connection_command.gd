class_name NodeConnectionCommand extends Command

var graph_view: MonologueGraphEdit
var from_node_name: String
var to_node_name: String
var from_property_name: String
var to_property_name: String


func _init(
	n_graph_view: MonologueGraphEdit,
	n_from_node_name: String,
	n_to_node_name: String,
	n_from_property_name: String,
	n_to_property_name: String
) -> void:
	graph_view = n_graph_view
	from_node_name = n_from_node_name
	to_node_name = n_to_node_name
	from_property_name = n_from_property_name
	to_property_name = n_to_property_name


func execute() -> void:
	# Recalculate port indices in case they changed
	var from_port = graph_view.get_port_index_for_property(from_node_name, from_property_name)
	var to_port = graph_view.get_port_index_for_property(to_node_name, to_property_name)

	if from_port >= 0 and to_port >= 0:
		graph_view.connect_node(from_node_name, from_port, to_node_name, to_port)
		# Register connection using property names, not port indices
		if graph_view.connection_manager:
			graph_view.connection_manager.register_connection_by_property(
				from_node_name, from_property_name, to_node_name, to_property_name
			)


func undo() -> void:
	# Recalculate port indices in case they changed
	var from_port = graph_view.get_port_index_for_property(from_node_name, from_property_name)
	var to_port = graph_view.get_port_index_for_property(to_node_name, to_property_name)

	if from_port >= 0 and to_port >= 0:
		graph_view.disconnect_node(from_node_name, from_port, to_node_name, to_port)
		# Unregister connection using property names
		if graph_view.connection_manager:
			graph_view.connection_manager.unregister_connection_by_property(
				from_node_name, from_property_name, to_node_name, to_property_name
			)


func get_description() -> String:
	return (
		"Connect %s.%s to %s.%s"
		% [from_node_name, from_property_name, to_node_name, to_property_name]
	)
