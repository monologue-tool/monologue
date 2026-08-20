## Moves a selection out of the document it sits in and into a section of its own, leaving a
## section node wired in where it used to be.
##
## One undo step, document included.
class_name ExtractSectionCommand extends Command

var storyline_id: String
var nodes: Array[InspectableNode]
var section_name: String

var _section: StorylineDocument
## The node the section is entered by.
var _entry: InspectableNode
## The section node left behind in the storyline.
var _placed: InspectableNode
## Wires between two selected nodes.
var _inside: Array[NodeConnection] = []
## Wires with one end outside the selection.
var _outside: Array[NodeConnection] = []
## The outside ends, moved onto the section node.
var _rerouted: Array[NodeConnection] = []
var _root_wire: NodeConnection


func _init(
	p_storyline_id: String, p_nodes: Array[InspectableNode], p_section_name: String = ""
) -> void:
	storyline_id = p_storyline_id
	nodes = p_nodes
	section_name = p_section_name


## Why the selection cannot become a section, or "" when it can.
static func refuse_reason(
	storyline: StorylineDocument, selection: Array[InspectableNode]
) -> String:
	if selection.is_empty():
		return "Nothing is selected."

	var selected: Dictionary[String, bool] = {}
	for node: InspectableNode in selection:
		selected[node.get_id()] = true

	var ways_in: int = 0
	for node: InspectableNode in selection:
		if _reached_from_within(storyline, node, selected):
			continue
		ways_in += 1

	if ways_in != 1:
		return (
			"A section is entered in one place, and this selection is entered in %d. "
			+ "Select a single chain."
		) % ways_in

	# A section is left by a chain that ran out, so a node the story leaves from must be
	# the end of its chain inside.
	for node: InspectableNode in selection:
		var leaves: bool = false
		var carries_on: bool = false
		for wire: NodeConnection in storyline.get_outgoing(node.get_id()):
			if selected.has(wire.to_node_id):
				carries_on = true
			else:
				leaves = true
		if leaves and carries_on:
			return (
				"'%s' branches both inside and outside the selection, so the section would "
				+ "have no way out of it. Take the whole branch in."
			) % Util.to_readable_name(node.get_type())

	return ""


static func _reached_from_within(
	storyline: StorylineDocument, node: InspectableNode, selected: Dictionary[String, bool]
) -> bool:
	for wire: NodeConnection in storyline.get_incoming(node.get_id()):
		if selected.has(wire.from_node_id):
			return true
	return false


func execute() -> void:
	var project: MonologueProject = ProjectManager.current_project
	var storyline: StorylineDocument = project.get_storyline(storyline_id)
	if storyline == null:
		return
	if _section == null and not _plan(project, storyline):
		return

	# The same document, so every reference to it still resolves after a redo.
	if project.get_storyline(_section.id) == null:
		project.storylines.append(_section)
		project.observe_storylines()

	for node: InspectableNode in nodes:
		storyline.remove_node(node)
	for node: InspectableNode in nodes:
		_section.register_node(node)
	for wire: NodeConnection in _inside:
		_section.add_connection(wire)
	_section.add_connection(_root_wire)

	storyline.add_node(_placed)
	for wire: NodeConnection in _rerouted:
		storyline.add_connection(wire)

	EventBus.storylines_changed.emit()
	EventBus.refresh_graph.emit()


func undo() -> void:
	var project: MonologueProject = ProjectManager.current_project
	var storyline: StorylineDocument = project.get_storyline(storyline_id)
	if storyline == null or _section == null:
		return

	storyline.remove_node(_placed)
	for node: InspectableNode in nodes:
		_section.remove_node(node)
	project.storylines.erase(_section)

	for node: InspectableNode in nodes:
		storyline.register_node(node)
	for wire: NodeConnection in _inside:
		storyline.add_connection(wire)
	for wire: NodeConnection in _outside:
		storyline.add_connection(wire)

	EventBus.storylines_changed.emit()
	EventBus.refresh_graph.emit()


func get_description() -> String:
	return "Extract %d nodes into a section" % nodes.size()


## Works out what moves where, once.
func _plan(project: MonologueProject, storyline: StorylineDocument) -> bool:
	if not refuse_reason(storyline, nodes).is_empty():
		return false

	_inside.clear()
	_outside.clear()
	_rerouted.clear()

	var selected: Dictionary[String, bool] = {}
	for node: InspectableNode in nodes:
		selected[node.get_id()] = true

	for node: InspectableNode in nodes:
		if not _reached_from_within(storyline, node, selected):
			_entry = node

	for wire: NodeConnection in storyline.connections:
		var leaves_selection: bool = selected.has(wire.from_node_id)
		var enters_selection: bool = selected.has(wire.to_node_id)
		if leaves_selection and enters_selection:
			_inside.append(wire)
		elif leaves_selection or enters_selection:
			_outside.append(wire)

	_section = project.add_section(storyline_id, section_name)
	if _section == null:
		return false

	_root_wire = NodeConnection.create(
		_section.get_root().get_id(),
		"root",
		_entry.get_id(),
		_entry.get_main_property().name
	)

	_placed = MonologueRegistry.get_instance().create_node("section", storyline.history)
	_placed.get_property("target").set_value(_section.id)
	_placed.get_property("editor_position").set_value(_entry.get_property_value("editor_position"))

	for wire: NodeConnection in _outside:
		_rerouted.append(_moved_onto_placed(wire, selected))
	return true


## One outside wire, with whichever end was in the selection moved onto the section node.
## A departure leaves by the exit named after the node whose chain ran out there.
func _moved_onto_placed(
	wire: NodeConnection, selected: Dictionary[String, bool]
) -> NodeConnection:
	if selected.has(wire.to_node_id):
		return NodeConnection.create(
			wire.from_node_id,
			wire.from_property,
			_placed.get_id(),
			_placed.get_main_property().name,
			wire.from_item_id
		)

	return NodeConnection.create(
		_placed.get_id(),
		"exits",
		wire.to_node_id,
		wire.to_property,
		NodeConnection.EXTERNAL_PREFIX + wire.from_node_id,
		wire.to_item_id
	)
