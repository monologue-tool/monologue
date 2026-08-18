class_name AddNodesCommand extends Command

var storyline_id: String
var nodes: Array = []
## Wires the undo took away with the nodes, put back when the add is redone.
var _removed_connections: Array[NodeConnection] = []


func _init(
	p_storyline_id: String,
	p_nodes: Array,
) -> void:
	storyline_id = p_storyline_id
	nodes = p_nodes


func execute() -> void:
	var storyline: StorylineDocument = ProjectManager.current_project.get_storyline(storyline_id)
	if not storyline:
		return

	for node: InspectableNode in nodes:
		storyline.add_node(node)
	for connection: NodeConnection in _removed_connections:
		storyline.add_connection(connection)
	_removed_connections.clear()
	EventBus.refresh_graph.emit()


func undo() -> void:
	var storyline: StorylineDocument = ProjectManager.current_project.get_storyline(storyline_id)
	if not storyline:
		return

	_removed_connections.clear()
	for node: InspectableNode in nodes:
		_removed_connections.append_array(storyline.remove_node(node))
	EventBus.refresh_graph.emit()


func get_description() -> String:
	return "Add %s nodes" % nodes.size()
