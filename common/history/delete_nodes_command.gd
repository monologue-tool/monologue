## Removes nodes from a storyline, along with the wires that reached them.
##
## A wire to a node that is gone means nothing, so removing the node takes its
## connections with it. Undo puts both back: the command holds on to the node instances
## and to the wires the storyline handed over, so they return with the ids they always
## had and every reference to them resolves again.
class_name DeleteNodesCommand extends AddNodesCommand


func execute() -> void:
	var storyline: StorylineDocument = _get_storyline()
	if not storyline:
		return

	_removed_connections.clear()
	for node: InspectableNode in nodes:
		_removed_connections.append_array(storyline.remove_node(node))

	EventBus.refresh_graph.emit()


func undo() -> void:
	var storyline: StorylineDocument = _get_storyline()
	if not storyline:
		return

	for node: InspectableNode in nodes:
		storyline.add_node(node)
	for connection: NodeConnection in _removed_connections:
		storyline.add_connection(connection)
	_removed_connections.clear()

	EventBus.refresh_graph.emit()


func get_description() -> String:
	return "Delete %s nodes" % nodes.size()


func _get_storyline() -> StorylineDocument:
	return ProjectManager.current_project.get_storyline(storyline_id)
