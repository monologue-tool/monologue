## Command for connecting/disconnecting nodes in the graph with undo/redo support.
##
## Encapsulates a node connection operation in the graph editor, allowing
## connections to be created and removed reversibly.
class_name NodeConnectionCommand extends Command

## The graph edit view containing the nodes.
var graph_view: MonologueGraphEdit

## Name of the source node for the connection.
var from_node: StringName

## Name of the destination node for the connection.
var to_node: StringName

## Output port index on the source node.
var from_port: int

## Input port index on the destination node.
var to_port: int


## Initializes a node connection command.
##
## [param n_graph_view] The MonologueGraphEdit containing the nodes.
## [br][br]
## [param n_from_node] Name of the source node.
## [br][br]
## [param n_to_node] Name of the destination node.
## [br][br]
## [param n_from_port] Output port on the source node.
## [br][br]
## [param n_to_port] Input port on the destination node.
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


## Executes the connection by creating a link between the nodes.
func execute() -> void:
	graph_view.connect_node(from_node, from_port, to_node, to_port)


## Undoes the connection by removing the link between the nodes.
func undo() -> void:
	graph_view.disconnect_node(from_node, from_port, to_node, to_port)


## Returns a description of this command for display purposes.
func get_description() -> String:
	var arguments = [from_node, from_port, to_node, to_port]
	return "Connect %s port %d to %s port %d" % arguments
