# gdlint: disable=max-public-methods
extends GdUnitTestSuite

## Wires live in one list on the storyline. Every property's connected_from and
## connected_to is a view onto it, so there is no second copy to disagree with the
## first, and nothing to leave behind when a wire or a node goes away.

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


func _connection_keys() -> Array[String]:
	var keys: Array[String] = []
	for connection: NodeConnection in _storyline.connections:
		keys.append(connection.to_key())
	return keys


func _issue_codes(document: StorylineDocument) -> Array[StringName]:
	var result: ValidationResult = ValidationResult.ok()
	document.validate_object(result, ValidationContext.new())
	var codes: Array[StringName] = []
	for issue: ValidationIssue in result.issues:
		codes.append(issue.code)
	return codes


static func _read_id(node_data: Dictionary) -> String:
	var raw: Variant = node_data.get("id")
	return str((raw as Dictionary).get("value", "")) if raw is Dictionary else ""


func test_connect_then_disconnect_leaves_no_trace() -> void:
	var manager: ConnectionManager = ConnectionManager.new(_storyline)
	var first: InspectableNode = _storyline.create_node("text")
	var second: InspectableNode = _storyline.create_node("text")
	var from_name: String = first.get_main_property().name
	var to_name: String = second.get_main_property().name
	var _before: int = _storyline.connections.size()

	manager.register_connection_by_property(first.get_id(), from_name, second.get_id(), to_name)
	assert_int(_storyline.connections.size()).is_equal(_before + 1)
	assert_array(first.get_main_property().connected_to).is_not_empty()
	assert_array(second.get_main_property().connected_from).is_not_empty()

	manager.unregister_connection_by_property(first.get_id(), from_name, second.get_id(), to_name)

	assert_int(_storyline.connections.size()).is_equal(_before)
	assert_array(first.get_main_property().connected_to).is_empty()
	assert_array(second.get_main_property().connected_from).is_empty()


func test_the_same_wire_is_never_stored_twice() -> void:
	var manager: ConnectionManager = ConnectionManager.new(_storyline)
	var first: InspectableNode = _storyline.create_node("text")
	var second: InspectableNode = _storyline.create_node("text")
	var from_name: String = first.get_main_property().name
	var to_name: String = second.get_main_property().name
	var _before: int = _storyline.connections.size()

	for _attempt: int in range(3):
		manager.register_connection_by_property(first.get_id(), from_name, second.get_id(), to_name)

	assert_int(_storyline.connections.size()).is_equal(_before + 1)


func test_both_views_agree_because_there_is_only_one_list() -> void:
	var root: InspectableNode = _node("root")
	var sentence: InspectableNode = _node("sentence")

	var outgoing: Array[Dictionary] = root.get_main_property().connected_to
	var incoming: Array[Dictionary] = sentence.get_main_property().connected_from

	assert_int(outgoing.size()).is_equal(1)
	assert_int(incoming.size()).is_equal(1)
	assert_str(str(outgoing[0]["node_id"])).is_equal(sentence.get_id())
	assert_str(str(incoming[0]["node_id"])).is_equal(root.get_id())


func test_deleting_a_node_removes_exactly_its_connections() -> void:
	var root: InspectableNode = _node("root")
	var root_id: String = root.get_id()
	var _before: int = _storyline.connections.size()
	var touching: int = (
		_storyline.get_outgoing(root_id).size() + _storyline.get_incoming(root_id).size()
	)
	assert_int(touching).override_failure_message(
		"The root node should start out wired; this test proves nothing otherwise."
	).is_greater(0)

	var removed: Array[NodeConnection] = _storyline.remove_node(root)

	assert_int(removed.size()).is_equal(touching)
	assert_int(_storyline.connections.size()).is_equal(_before - touching)
	for connection: NodeConnection in _storyline.connections:
		assert_bool(connection.involves(root_id)).override_failure_message(
			"%s survived the deletion of %s." % [connection, root_id]
		).is_false()


func test_undoing_a_node_delete_restores_its_connections() -> void:
	var _before: Array[String] = _connection_keys()
	var command: DeleteNodesCommand = DeleteNodesCommand.new(_storyline.id, [_node("root")])

	_project.command_manager.execute(command)
	assert_int(_storyline.connections.size()).is_less(_before.size())

	_project.command_manager.undo()

	assert_array(_connection_keys()).contains_exactly_in_any_order(_before)


func test_connections_survive_a_dictionary_round_trip() -> void:
	var _before: Array[String] = _connection_keys()

	var loaded: StorylineDocument = auto_free(
		StorylineDocument.new("loaded", _project.command_manager)
	)
	loaded._from_dict(_storyline._to_dict())

	var keys: Array[String] = []
	for connection: NodeConnection in loaded.connections:
		keys.append(connection.to_key())
	assert_array(keys).contains_exactly_in_any_order(_before)


func test_a_dangling_connection_in_a_loaded_file_is_reported_not_dropped() -> void:
	var data: Dictionary = _storyline._to_dict()
	var wires: Array = data["connections"]
	wires.append(
		NodeConnection.create(
			_node("root").get_id(), _node("root").get_main_property().name, "sentence-GONE", "sentence"
		)._to_dict()
	)

	var loaded: StorylineDocument = auto_free(
		StorylineDocument.new("loaded", _project.command_manager)
	)
	loaded._from_dict(data)

	# Kept, so that restoring the missing node repairs the wire instead of needing it
	# drawn again.
	assert_int(loaded.connections.size()).is_equal(wires.size())
	assert_array(_issue_codes(loaded)).contains([&"broken_connection"])


func test_a_file_written_before_the_connection_list_still_loads_its_wires() -> void:
	var data: Dictionary = _storyline._to_dict()
	var wires: Array = data["connections"]
	data.erase("connections")

	for wire: Dictionary in wires:
		for node_data: Dictionary in data["nodes"]:
			if _read_id(node_data) != wire["from_node_id"]:
				continue
			var property_data: Dictionary = node_data[wire["from_property"]]
			var outgoing: Array = property_data.get_or_add("to_node", [])
			outgoing.append(
				{"node_id": wire["to_node_id"], "property_name": wire["to_property"]}
			)

	var loaded: StorylineDocument = auto_free(
		StorylineDocument.new("legacy", _project.command_manager)
	)
	loaded._from_dict(data)

	assert_int(loaded.connections.size()).is_equal(wires.size())
