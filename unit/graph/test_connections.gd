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


func test_an_empty_reroute_takes_anything_and_gives_back_anything() -> void:
	var bend: InspectableNode = _storyline.create_node("reroute")

	assert_dict(bend.carried_port(bend.get_main_property())).override_failure_message(
		"A reroute with nothing plugged in claimed to be carrying something."
	).is_empty()
	assert_int(_given_back(bend)).is_equal(
		MonologueRegistry.get_instance().get_field_type_id("any")
	)


func test_a_reroute_gives_back_only_what_was_plugged_into_it() -> void:
	# The whole of what a reroute is: it takes in anything, so it can always be rewired, and
	# hands on only what it was given, so it cannot turn one kind of thing into another on
	# the way past.
	var manager: ConnectionManager = ConnectionManager.new(_storyline)
	var source: InspectableNode = _storyline.create_node("text")
	var bend: InspectableNode = _storyline.create_node("reroute")

	manager.register_connection_by_property(
		source.get_id(), source.get_main_property().name,
		bend.get_id(), bend.get_main_property().name
	)

	var registry: MonologueRegistry = MonologueRegistry.get_instance()
	assert_int(_given_back(bend)).override_failure_message(
		"A reroute fed a text did not give a text back."
	).is_equal(registry.get_field_type_id("text"))
	assert_str(str(bend.carried_port(bend.get_main_property())["label"])).is_equal("text")

	# What it takes in is untouched, or it could never be rewired without first being
	# unplugged from whatever it feeds.
	assert_int(_taken_in(bend)).is_equal(registry.get_field_type_id("any"))

	# And a bend in the wire is still a bend however many of them there are.
	var second: InspectableNode = _storyline.create_node("reroute")
	manager.register_connection_by_property(
		bend.get_id(), bend.get_main_property().name,
		second.get_id(), second.get_main_property().name
	)
	assert_int(_given_back(second)).override_failure_message(
		"A type stopped at the first bend instead of carrying on down the chain."
	).is_equal(registry.get_field_type_id("text"))


func test_a_reroute_wired_in_a_circle_carries_nothing_rather_than_hanging() -> void:
	var manager: ConnectionManager = ConnectionManager.new(_storyline)
	var first: InspectableNode = _storyline.create_node("reroute")
	var second: InspectableNode = _storyline.create_node("reroute")

	manager.register_connection_by_property(
		first.get_id(), first.get_main_property().name,
		second.get_id(), second.get_main_property().name
	)
	manager.register_connection_by_property(
		second.get_id(), second.get_main_property().name,
		first.get_id(), first.get_main_property().name
	)

	assert_int(_given_back(first)).override_failure_message(
		"A reroute wired in a circle did not give up on working out what it carries."
	).is_equal(MonologueRegistry.get_instance().get_field_type_id("any"))


func test_a_reroute_says_so_when_it_hands_on_what_the_far_end_cannot_take() -> void:
	# Rewiring what feeds a reroute can leave it handing something else on to a port that was
	# never able to take it, and the wire looks exactly as it did before.
	var manager: ConnectionManager = ConnectionManager.new(_storyline)
	var wording: InspectableNode = _storyline.create_node("text")
	var bend: InspectableNode = _storyline.create_node("reroute")
	var pause: InspectableNode = _storyline.create_node("wait")

	manager.register_connection_by_property(
		wording.get_id(), wording.get_main_property().name,
		bend.get_id(), bend.get_main_property().name
	)
	manager.register_connection_by_property(
		bend.get_id(), bend.get_main_property().name, pause.get_id(), "seconds"
	)

	var context: ValidationContext = ValidationContext.new()
	context.object = bend
	context.project = _project
	context.phase = ValidationContext.Phase.AUDIT

	var result: ValidationResult = ValidationResult.ok()
	bend.validate_object(result, context)

	assert_array(result.with_code(&"rerouted_into_the_wrong_type")).override_failure_message(
		"A text was carried into a port that takes a number and nobody said anything."
	).is_not_empty()


## The port a node hands on, as the graph would draw it.
func _given_back(node: InspectableNode) -> int:
	return int(NodePort.of(node, node.get_main_property())["type_id"])


## The port a node takes in, which is always the one it declares.
func _taken_in(node: InspectableNode) -> int:
	return MonologueRegistry.get_instance().get_field_type_id(node.get_main_property().type)


func test_two_waypoints_of_one_name_each_say_the_other_is_there() -> void:
	# What nothing checking one property at a time can see: each of the two is perfectly fine
	# on its own, and a jump aiming there reaches whichever comes first. The runtime notices
	# it too, once, while playing; this is so it is known before anyone plays.
	var first: InspectableNode = _storyline.create_node("waypoint")
	var second: InspectableNode = _storyline.create_node("waypoint")
	var alone: InspectableNode = _storyline.create_node("waypoint")
	first.get_property("label").set_value("hub")
	second.get_property("label").set_value("hub")
	alone.get_property("label").set_value("elsewhere")

	assert_array(_named_twice(first)).override_failure_message(
		"A waypoint sharing its name with another did not say so."
	).is_not_empty()
	assert_array(_named_twice(second)).override_failure_message(
		"Only one of the pair was named, so the author sees half the problem."
	).is_not_empty()
	assert_array(_named_twice(alone)).override_failure_message(
		"A waypoint nobody shares a name with was complained about."
	).is_empty()


func _named_twice(waypoint: InspectableNode) -> Array[ValidationIssue]:
	var context: ValidationContext = ValidationContext.new()
	context.object = waypoint
	context.project = _project
	context.phase = ValidationContext.Phase.AUDIT

	var result: ValidationResult = ValidationResult.ok()
	waypoint.validate_object(result, context)
	return result.with_code(&"waypoints_share_a_name")

