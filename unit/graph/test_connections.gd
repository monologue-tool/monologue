extends GdUnitTestSuite

## Wires live in one list on the storyline. Every property's connected_from and connected_to
## is a view onto it, so there is no second copy to disagree with the first, and nothing to
## leave behind when a wire or a node goes away.
##
## Undoing a node delete is checked in unit/references/, which also watches the mirrored
## view come back.

var _project: MonologueProject
var _storyline: StorylineDocument


func before_test() -> void:
	_project = auto_free(MonologueProject.new())
	await _project.ready
	ProjectManager.current_project = _project
	_storyline = _project.storylines[0]


func after_test() -> void:
	ProjectManager.current_project = null


func _node(node_type: String) -> InspectableNode:
	for node: InspectableNode in _storyline.nodes:
		if node.get_type() == node_type:
			return node
	return null


func _connection_keys(document: StorylineDocument) -> Array[String]:
	var keys: Array[String] = []
	for connection: NodeConnection in document.connections:
		keys.append(connection.to_key())
	return keys


func test_a_wire_appears_once_in_one_list_and_in_both_views() -> void:
	var manager: ConnectionManager = ConnectionManager.new(_storyline)
	var first: InspectableNode = _storyline.create_node("text")
	var second: InspectableNode = _storyline.create_node("text")
	var from_name: String = first.get_main_property().name
	var to_name: String = second.get_main_property().name
	var initial: int = _storyline.connections.size()

	for _attempt: int in range(3):
		manager.register_connection_by_property(
			first.get_id(), from_name, second.get_id(), to_name
		)

	assert_int(_storyline.connections.size()).override_failure_message(
		"The same wire was stored more than once."
	).is_equal(initial + 1)
	assert_str(str(first.get_main_property().connected_to[0]["node_id"])).is_equal(second.get_id())
	assert_str(str(second.get_main_property().connected_from[0]["node_id"])).is_equal(first.get_id())

	manager.unregister_connection_by_property(first.get_id(), from_name, second.get_id(), to_name)

	assert_int(_storyline.connections.size()).is_equal(initial)
	assert_array(first.get_main_property().connected_to).is_empty()
	assert_array(second.get_main_property().connected_from).is_empty()


func test_deleting_a_node_takes_exactly_its_own_wires() -> void:
	var root: InspectableNode = _node("root")
	var root_id: String = root.get_id()
	var initial: int = _storyline.connections.size()
	var touching: int = (
		_storyline.get_outgoing(root_id).size() + _storyline.get_incoming(root_id).size()
	)
	assert_int(touching).override_failure_message(
		"The root node should start out wired; this test proves nothing otherwise."
	).is_greater(0)

	var removed: Array[NodeConnection] = _storyline.remove_node(root)

	assert_int(removed.size()).is_equal(touching)
	assert_int(_storyline.connections.size()).is_equal(initial - touching)
	for connection: NodeConnection in _storyline.connections:
		assert_bool(connection.involves(root_id)).override_failure_message(
			"%s survived the deletion of %s." % [connection, root_id]
		).is_false()


func test_a_saved_storyline_comes_back_with_its_wires_and_says_what_is_broken() -> void:
	var initial: Array[String] = _connection_keys(_storyline)
	var data: Dictionary = _storyline._to_dict()

	var loaded: StorylineDocument = auto_free(
		StorylineDocument.new("loaded", _project.command_manager)
	)
	loaded._from_dict(data)
	assert_array(_connection_keys(loaded)).contains_exactly_in_any_order(initial)

	# A wire pointing at a node that is gone is kept and reported: dropping it silently
	# would lose the author's intent along with the problem.
	var root: InspectableNode = _node("root")
	(data["connections"] as Array).append(
		NodeConnection.create(
			root.get_id(), root.get_main_property().name, "sentence-GONE", "sentence"
		)._to_dict()
	)
	var dangling: StorylineDocument = auto_free(
		StorylineDocument.new("dangling", _project.command_manager)
	)
	dangling._from_dict(data)

	assert_int(dangling.connections.size()).is_equal((data["connections"] as Array).size())
	var result: ValidationResult = ValidationResult.ok()
	dangling.validate_object(result, ValidationContext.new())
	assert_array(result.with_code(&"broken_connection")).is_not_empty()

	# A file written before wires existed simply has none.
	data.erase("connections")
	var wireless: StorylineDocument = auto_free(
		StorylineDocument.new("wireless", _project.command_manager)
	)
	wireless._from_dict(data)
	assert_array(wireless.connections).is_empty()


func test_a_choice_shows_an_option_by_name_and_stops_when_unwired() -> void:
	var choice: InspectableNode = _node("choice")
	var option: InspectableNode = _node("option")
	option.set_property_value("text", {"en": "Open the door"})

	var externals: Array[Dictionary] = choice.get_external_list_items("choices")

	assert_int(externals.size()).is_equal(1)
	assert_str(str(externals[0]["name"])).is_equal("Open the door")
	# Drawing the choice is what makes it subscribe to what it shows. Without this it kept
	# the name the option had at the moment it was wired.
	assert_bool(option.property_changed.is_connected(choice._on_source_property_changed)).is_true()

	for connection: NodeConnection in _storyline.get_outgoing(option.get_id()):
		_storyline.remove_connection(connection)
	choice.get_external_list_items("choices")

	assert_bool(option.property_changed.is_connected(choice._on_source_property_changed)).is_false()
