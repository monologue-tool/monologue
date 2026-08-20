extends GdUnitTestSuite

## Turning a flat chain into a section. Nothing forces an author to decompose, so this is the
## gesture the whole thing rests on: it has to be exact, and it has to be one undo step.

var _project: MonologueProject
var _storyline: StorylineDocument


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_project = auto_free(MonologueProject.new())
	await _project.ready
	ProjectManager.current_project = _project

	# Every case builds its own chain, so the shipped one is in the way.
	_storyline = _project.storylines[0]
	for node: InspectableNode in _storyline.nodes.duplicate():
		if node.get_type() != "root":
			_storyline.remove_node(node)


func after_test() -> void:
	ProjectManager.current_project = null
	MonologueRegistry.reset_instance()


## By each end's own flow port, which a node type names after itself, unless told otherwise.
func _wire(from_node: InspectableNode, to_node: InspectableNode, from_port: String = "") -> void:
	_storyline.add_connection(
		NodeConnection.create(
			from_node.get_id(),
			from_port if not from_port.is_empty() else from_node.get_type(),
			to_node.get_id(),
			to_node.get_type()
		)
	)


func _first_of_type(document: StorylineDocument, node_type: String) -> InspectableNode:
	for node: InspectableNode in document.nodes:
		if node.get_type() == node_type:
			return node
	return null


## Every node and every wire as text, so two states can be compared whole rather than
## spot-checked.
func _shape_of(document: StorylineDocument) -> Array[String]:
	var shape: Array[String] = []
	for node: InspectableNode in document.nodes:
		shape.append("node %s %s" % [node.get_type(), node.get_id()])
	for wire: NodeConnection in document.connections:
		shape.append(
			"wire %s.%s -> %s.%s"
			% [wire.from_node_id, wire.from_property, wire.to_node_id, wire.to_property]
		)
	shape.sort()
	return shape


## root to first to middle to tail, of which the middle two are what gets taken out.
func _chain() -> Array[InspectableNode]:
	var first: InspectableNode = _storyline.create_node("sentence")
	var middle: InspectableNode = _storyline.create_node("sentence")
	var tail: InspectableNode = _storyline.create_node("sentence")

	_wire(_storyline.get_root(), first)
	_wire(first, middle)
	_wire(middle, tail)
	return [first, middle, tail]


func test_a_chain_becomes_a_section_wired_in_where_it_stood() -> void:
	var chain: Array[InspectableNode] = _chain()
	var moved: Array[InspectableNode] = [chain[0], chain[1]]

	assert_str(ExtractSectionCommand.refuse_reason(_storyline, moved)).is_empty()
	_project.command_manager.execute(ExtractSectionCommand.new(_storyline.id, moved))

	assert_int(_project.sections().size()).is_equal(1)
	var section: StorylineDocument = _project.sections()[0]
	assert_str(section.parent).is_equal(_storyline.id)

	assert_object(section.get_node(chain[0].get_id())).override_failure_message(
		"The selection did not arrive in the section."
	).is_not_null()
	assert_object(_storyline.get_node(chain[0].get_id())).override_failure_message(
		"A node that moved was left in the storyline as well."
	).is_null()
	assert_int(section.get_outgoing(chain[0].get_id()).size()).override_failure_message(
		"The wire between two moved nodes did not go with them."
	).is_equal(1)

	var into: Array[NodeConnection] = section.get_incoming(chain[0].get_id())
	assert_int(into.size()).is_equal(1)
	assert_str(into[0].from_node_id).override_failure_message(
		"The section is not entered by its own root."
	).is_equal(section.get_root().get_id())


func test_what_reached_the_selection_now_reaches_the_section_node() -> void:
	var chain: Array[InspectableNode] = _chain()
	var moved: Array[InspectableNode] = [chain[0], chain[1]]
	_project.command_manager.execute(ExtractSectionCommand.new(_storyline.id, moved))

	var placed: InspectableNode = _first_of_type(_storyline, "section")
	assert_object(placed).override_failure_message(
		"Nothing was left in the storyline where the selection had been."
	).is_not_null()
	assert_str(str(placed.get_property_value("target"))).is_equal(_project.sections()[0].id)

	var arriving: Array[NodeConnection] = _storyline.get_incoming(placed.get_id())
	assert_int(arriving.size()).is_equal(1)
	assert_str(arriving[0].from_node_id).is_equal(_storyline.get_root().get_id())

	var leaving: Array[NodeConnection] = _storyline.get_outgoing(placed.get_id())
	assert_int(leaving.size()).is_equal(1)
	assert_str(leaving[0].to_node_id).is_equal(chain[2].get_id())
	assert_str(leaving[0].from_item_id).override_failure_message(
		"The way out is not named after the node whose chain ran out there."
	).is_equal(NodeConnection.EXTERNAL_PREFIX + chain[1].get_id())


func test_undoing_an_extraction_puts_the_storyline_back_exactly() -> void:
	var chain: Array[InspectableNode] = _chain()
	var moved: Array[InspectableNode] = [chain[0], chain[1]]
	var before: Array[String] = _shape_of(_storyline)

	_project.command_manager.execute(ExtractSectionCommand.new(_storyline.id, moved))
	assert_array(_shape_of(_storyline)).override_failure_message(
		"The extraction changed nothing, so this proves nothing about the undo."
	).is_not_equal(before)

	assert_bool(_project.command_manager.undo()).is_true()

	assert_array(_shape_of(_storyline)).override_failure_message(
		"One undo did not put the storyline back the way it was."
	).is_equal(before)
	assert_array(_project.sections()).override_failure_message(
		"The section outlived the undo that made it."
	).is_empty()


func test_redoing_it_uses_the_same_section_rather_than_a_second_one() -> void:
	# Every reference to a section is by id, so a redo building a new document would leave
	# whatever pointed at the first one pointing at nothing.
	var chain: Array[InspectableNode] = _chain()
	var moved: Array[InspectableNode] = [chain[0], chain[1]]

	_project.command_manager.execute(ExtractSectionCommand.new(_storyline.id, moved))
	var was: String = _project.sections()[0].id
	assert_bool(_project.command_manager.undo()).is_true()
	assert_bool(_project.command_manager.redo()).is_true()

	assert_int(_project.sections().size()).is_equal(1)
	assert_str(_project.sections()[0].id).is_equal(was)
	assert_str(
		str(_first_of_type(_storyline, "section").get_property_value("target"))
	).is_equal(was)


func test_a_selection_entered_in_two_places_is_refused() -> void:
	# Picking one of the two silently would be worse than saying so.
	var first: InspectableNode = _storyline.create_node("sentence")
	var second: InspectableNode = _storyline.create_node("sentence")
	_wire(_storyline.get_root(), first)
	_wire(_storyline.get_root(), second)

	var refused: String = ExtractSectionCommand.refuse_reason(_storyline, [first, second])
	assert_str(refused).override_failure_message(
		"Two separate chains were accepted as one section."
	).is_not_empty()
	assert_str(refused).contains("2")


func test_a_node_branching_both_in_and_out_of_the_selection_is_refused() -> void:
	# Its chain has not run out inside the section, so there is no exit to come back by.
	var branch: InspectableNode = _storyline.create_node("condition")
	var kept: InspectableNode = _storyline.create_node("sentence")
	var outside: InspectableNode = _storyline.create_node("sentence")

	_wire(_storyline.get_root(), branch)
	_wire(branch, kept, "pass")
	_wire(branch, outside, "fail")

	assert_str(
		ExtractSectionCommand.refuse_reason(_storyline, [branch, kept])
	).override_failure_message(
		"A node branching out of the selection was accepted, so its wire would dangle."
	).is_not_empty()
