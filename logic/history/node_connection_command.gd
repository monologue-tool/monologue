class_name NodeConnectionCommand extends Command

var graph_view: MonologueGraphEdit
var from_node: StringName
var to_node: StringName
var from_port: int
var to_port: int


func _init(
	n_graph_view: MonologueGraphEdit,
	n_from_node: StringName,
	n_to_node: StringName,
	n_from_port: int,
	n_to_port: int
) -> void:
	graph_view = n_graph_view
	from_node = n_from_node
	to_node = n_to_node
	from_port = n_from_port
	to_port = n_to_port


func execute() -> void:
	# TODO: Maybe use `propagate_connection`
	graph_view.connect_node(from_node, from_port, to_node, to_port)


func undo() -> void:
	graph_view.disconnect_node(from_node, from_port, to_node, to_port)


func get_description() -> String:
	var arguments = [from_node, from_port, to_node, to_port]
	return "Connect %s port %d to %s port %d" % arguments
