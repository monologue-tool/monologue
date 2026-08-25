## Removes nodes from a storyline, along with the wires that reached them and, when told to,
## the sections those nodes were running.
##
## A wire to a node that is gone means nothing, so removing the node takes its
## connections with it. Undo puts both back: the command holds on to the node instances
## and to the wires the storyline handed over, so they return with the ids they always
## had and every reference to them resolves again. A section is held the same way, so a
## redo hands back the very document every reference already points at.
##
## Which sections go is decided by the caller and not here, because a cut is a move: the node
## comes back on a paste and the section it runs has to still be there.
class_name DeleteNodesCommand extends AddNodesCommand

## Sections to take down with the nodes, deepest last so undo can put parents back first.
var sections: Array[StorylineDocument] = []


func _init(
	p_storyline_id: String,
	p_nodes: Array,
	p_sections: Array[StorylineDocument] = [],
) -> void:
	super(p_storyline_id, p_nodes)
	sections = p_sections


## The sections these nodes run, and everything nested inside those.
##
## A section node can be copied, so one section can be run from two places. One still run
## from a node this delete leaves standing stays where it is.
static func sections_run_by(_nodes: Array) -> Array[StorylineDocument]:
	var project: MonologueProject = ProjectManager.current_project
	var going: Array[StorylineDocument] = []
	if project == null:
		return going

	var leaving: Dictionary[String, bool] = {}
	for node: InspectableNode in _nodes:
		leaving[node.get_id()] = true

	var run_elsewhere: Dictionary[String, bool] = {}
	for document: StorylineDocument in project.storylines:
		for node: InspectableNode in document.nodes:
			if node.get_type() == "section" and not leaving.has(node.get_id()):
				run_elsewhere[str(node.get_property_value("target"))] = true

	for node: InspectableNode in _nodes:
		if node.get_type() != "section":
			continue

		var section: StorylineDocument = project.get_storyline(
			str(node.get_property_value("target"))
		)
		if section == null or going.has(section) or run_elsewhere.has(section.id):
			continue
		going.append(section)

	var index: int = 0
	while index < going.size():
		for nested: StorylineDocument in project.get_sections_of(going[index].id):
			if not going.has(nested):
				going.append(nested)
		index += 1
	return going


func execute() -> void:
	var storyline: StorylineDocument = _get_storyline()
	if not storyline:
		return

	_removed_connections.clear()
	for node: InspectableNode in nodes:
		_removed_connections.append_array(storyline.remove_node(node))

	var project: MonologueProject = ProjectManager.current_project
	for section: StorylineDocument in sections:
		project.storylines.erase(section)

	if not sections.is_empty():
		EventBus.storyline_deleted.emit()
		EventBus.storylines_changed.emit()
		project.content_changed.emit()
	EventBus.refresh_graph.emit()


func undo() -> void:
	var storyline: StorylineDocument = _get_storyline()
	if not storyline:
		return

	var project: MonologueProject = ProjectManager.current_project
	for section: StorylineDocument in sections:
		if project.get_storyline(section.id) == null:
			project.storylines.append(section)

	for node: InspectableNode in nodes:
		storyline.add_node(node)
	for connection: NodeConnection in _removed_connections:
		storyline.add_connection(connection)
	_removed_connections.clear()

	if not sections.is_empty():
		project.observe_storylines()
		EventBus.storylines_changed.emit()
		project.content_changed.emit()
	EventBus.refresh_graph.emit()


func get_description() -> String:
	if sections.is_empty():
		return "Delete %s nodes" % nodes.size()
	return "Delete %s nodes and %s sections" % [nodes.size(), sections.size()]


func _get_storyline() -> StorylineDocument:
	return ProjectManager.current_project.get_storyline(storyline_id)
