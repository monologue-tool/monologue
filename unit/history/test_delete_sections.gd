extends GdUnitTestSuite

## What a delete takes down with it.
##
## A section node and the section it runs are made in one gesture, so losing one and keeping
## the other leaves a document nothing reaches, sitting in the tree with no way back into it.

var _project: MonologueProject
var _storyline: StorylineDocument


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_project = auto_free(MonologueProject.new())
	await _project.ready
	ProjectManager.current_project = _project

	_storyline = _project.storylines[0]
	for node: InspectableNode in _storyline.nodes.duplicate():
		if node.get_type() != "root":
			_storyline.remove_node(node)


func after_test() -> void:
	ProjectManager.current_project = null
	MonologueRegistry.reset_instance()


## A section node and the section it runs, made together the way the editor makes them.
func _running(inside: StorylineDocument, section_name: String) -> InspectableNode:
	var section: StorylineDocument = _project.add_section(inside.id, section_name)
	var node: InspectableNode = inside.create_node("section")
	node.get_property("target").set_value(section.id)
	return node


func _has_section(named: String) -> bool:
	for section: StorylineDocument in _project.sections():
		if section.name == named:
			return true
	return false


func test_deleting_a_section_node_takes_its_section_down() -> void:
	var node: InspectableNode = _running(_storyline, "detour")

	_storyline.history.execute(
		DeleteNodesCommand.new(
			_storyline.id, [node], DeleteNodesCommand.sections_run_by([node])
		)
	)

	assert_bool(_has_section("detour")).override_failure_message(
		"The section outlived the only node that ran it, so nothing reaches it any more."
	).is_false()


func test_undoing_that_delete_brings_the_section_back() -> void:
	# The same document and not a copy, or every reference to it would resolve to nothing.
	var node: InspectableNode = _running(_storyline, "detour")
	var section: StorylineDocument = _project.get_storyline(
		str(node.get_property_value("target"))
	)

	_storyline.history.execute(
		DeleteNodesCommand.new(
			_storyline.id, [node], DeleteNodesCommand.sections_run_by([node])
		)
	)
	_storyline.history.undo()

	assert_object(_project.get_storyline(section.id)).override_failure_message(
		"Undo put a section back under a new identity, so the node still runs nothing."
	).is_same(section)


func test_a_section_inside_the_one_going_down_goes_too() -> void:
	# It is stored inside its parent, so leaving it behind loses it just as thoroughly.
	var outer: InspectableNode = _running(_storyline, "outer")
	var section: StorylineDocument = _project.get_storyline(
		str(outer.get_property_value("target"))
	)
	_running(section, "inner")

	_storyline.history.execute(
		DeleteNodesCommand.new(
			_storyline.id, [outer], DeleteNodesCommand.sections_run_by([outer])
		)
	)

	assert_bool(_has_section("inner")).override_failure_message(
		"A section nested in the one deleted stayed behind, with no parent to reach it by."
	).is_false()


func test_a_section_another_node_still_runs_stays() -> void:
	# Copying a section node is how one section comes to be run from two places.
	var node: InspectableNode = _running(_storyline, "shared")
	var also: InspectableNode = _storyline.create_node("section")
	also.get_property("target").set_value(node.get_property_value("target"))

	var going: Array[StorylineDocument] = DeleteNodesCommand.sections_run_by([node])

	assert_array(going).override_failure_message(
		"Deleting one of two nodes running a section would have taken the section down."
	).is_empty()


func test_a_cut_leaves_the_section_standing() -> void:
	# A cut is a move: the node comes back on a paste, and it has to find its section there.
	var node: InspectableNode = _running(_storyline, "moved")

	_storyline.history.execute(DeleteNodesCommand.new(_storyline.id, [node]))

	assert_bool(_has_section("moved")).override_failure_message(
		"Cutting a section node destroyed its section, so pasting it back runs nothing."
	).is_true()


func test_deleting_an_ordinary_node_takes_nothing_down() -> void:
	var line: InspectableNode = _storyline.create_node("sentence")

	assert_array(DeleteNodesCommand.sections_run_by([line])).is_empty()
