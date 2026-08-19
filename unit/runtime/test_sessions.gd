extends GdUnitTestSuite

## A playthrough as something with a memory: readable, writable, and able to be put down and
## picked up again. What makes the editor a place to prototype rather than only to replay.

var _project: MonologueProject
var _path: String
var _runtime: MonologueRuntime
var _player: ScriptedPlayer
var _storyline: StorylineDocument


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_path = "%s/sessions_%d.mnlp" % [create_temp_dir("mnlp"), randi()]
	_project = auto_free(MonologueProject.new())
	await _project.ready

	# Holds at every line, the way a reader does, so a run can be looked at part way through.
	_player = ScriptedPlayer.new()
	_player.silent = true
	add_child(_player)

	_runtime = MonologueRuntime.new()
	_runtime.player = _player
	add_child(_runtime)

	_storyline = _project.storylines[0]
	for node: InspectableNode in _storyline.nodes.duplicate():
		if node.get_type() != "root":
			_storyline.remove_node(node)


func after_test() -> void:
	_runtime.queue_free()
	_player.queue_free()
	MonologueRegistry.reset_instance()


func _load() -> bool:
	ProjectWriter.write_project(_project, _path)
	return _runtime.load_project(_path)


func _declare_variable(variable_name: String, type_name: String, initial: Variant) -> String:
	var item: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		"variables", _project.command_manager
	)
	item.set_property_value("name", variable_name)
	item.set_property_value("type", type_name)
	item.set_property_value("value", initial)

	var document: CollectionDocument = _project.get_collection("variables")
	var records: Array = document.get_value().duplicate(true)
	records.append(item._to_dict())
	document.set_property_value("variables", records)
	return str(item.get_property_value("id"))


func _say(line: String) -> InspectableNode:
	var node: InspectableNode = _storyline.create_node("sentence")
	node.get_property("line").set_value({"en": line})
	return node


func _wire(
	from_node: InspectableNode, to_node: InspectableNode, from_port: String = ""
) -> void:
	_storyline.add_connection(
		NodeConnection.create(
			from_node.get_id(),
			from_port if not from_port.is_empty() else from_node.get_type(),
			to_node.get_id(),
			to_node.get_type()
		)
	)


## A node adding [param amount] to [param variable_id].
func _earn(variable_id: String, amount: int) -> InspectableNode:
	var node: InspectableNode = _storyline.create_node("variable")
	node.get_property("target").set_value(variable_id)
	node.get_property("operator").set_value("+")
	node.get_property("value").set_value(amount)
	return node


func test_a_variable_is_reached_by_its_name_and_not_by_its_id() -> void:
	var gold: String = _declare_variable("gold", "int", 3)
	_wire(_storyline.get_root(), _say("Held."))

	assert_bool(_load()).is_true()
	_runtime.start()

	assert_int(int(_runtime.get_var("gold", -1))).is_equal(3)
	assert_int(int(_runtime.get_var(gold, -1))).override_failure_message(
		"The id answered as though it were a name."
	).is_equal(-1)
	assert_bool(_runtime.set_var("never_declared", 1)).override_failure_message(
		"Writing a variable nobody declared was accepted."
	).is_false()
	assert_int(int(_runtime.variables().get("gold", -1))).is_equal(3)


func test_changing_a_variable_mid_run_changes_the_branch_that_follows() -> void:
	# The whole point of a session having a memory that can be written: the question "what if
	# this were 9" is answered without playing the story again.
	var gold: String = _declare_variable("gold", "int", 0)

	var held: InspectableNode = _say("Ask.")
	var branch: InspectableNode = _storyline.create_node("condition")
	branch.get_property("test").set_value({"variable": gold, "operator": ">=", "value": 5})

	_wire(_storyline.get_root(), held)
	_wire(held, branch)
	_wire(branch, _say("Rich."), "pass")
	_wire(branch, _say("Poor."), "fail")

	assert_bool(_load()).is_true()
	_runtime.start()

	assert_array(_player.said).is_equal(["Ask."])
	assert_bool(_runtime.set_var("gold", 9)).is_true()

	_player.answer_now()
	_runtime.session.advance(0.0)

	assert_array(_player.said).override_failure_message(
		"Writing the variable did not change the branch taken after it."
	).is_equal(["Ask.", "Rich."])


func test_a_saved_session_comes_back_where_it_was_with_what_it_had() -> void:
	var gold: String = _declare_variable("gold", "int", 0)
	var earn: InspectableNode = _earn(gold, 7)
	var held: InspectableNode = _say("Held.")
	_wire(_storyline.get_root(), earn)
	_wire(earn, held)

	assert_bool(_load()).is_true()
	_runtime.start()
	var was: String = _runtime.session.state.current_node()

	assert_bool(_runtime.save_session("chapter one")).is_true()
	_runtime.stop()

	assert_bool(_runtime.load_session("chapter one")).is_true()

	assert_int(int(_runtime.get_var("gold", -1))).override_failure_message(
		"The session came back without what it had picked up."
	).is_equal(7)
	assert_str(_runtime.session.state.current_node()).override_failure_message(
		"The session came back somewhere other than where it was put down."
	).is_equal(was)

	var history: Object = _runtime.service("history")
	assert_int((history.call(&"last", 10) as Array).size()).override_failure_message(
		"The backlog did not come back with the session."
	).is_greater(0)

	_runtime.delete_session("chapter one")


func test_a_session_is_listed_under_the_name_it_was_saved_with() -> void:
	_wire(_storyline.get_root(), _say("Held."))
	assert_bool(_load()).is_true()
	_runtime.start()

	assert_bool(_runtime.save_session("Chapter 2: the market")).is_true()

	var listed: Array[Dictionary] = _runtime.list_sessions()
	var names: PackedStringArray = []
	for saved: Dictionary in listed:
		names.append(str(saved.get("name", "")))

	assert_array(names).override_failure_message(
		"A session with punctuation in its name was not listed as it was written: %s"
		% str(names)
	).contains(["Chapter 2: the market"])

	assert_bool(_runtime.delete_session("Chapter 2: the market")).is_true()
	assert_bool(_runtime.load_session("Chapter 2: the market")).override_failure_message(
		"A deleted session was still there."
	).is_false()


func test_a_move_inside_a_playthrough_keeps_what_a_new_one_would_lose() -> void:
	# The hub: a menu, a button per section, and the story coming back to the menu.
	var gold: String = _declare_variable("gold", "int", 0)
	var earn: InspectableNode = _earn(gold, 7)
	var held: InspectableNode = _say("Held.")
	_wire(_storyline.get_root(), earn)
	_wire(earn, held)

	var elsewhere: StorylineDocument = _project.add_section(_storyline.id, "elsewhere")
	var there: InspectableNode = elsewhere.create_node("sentence")
	there.get_property("line").set_value({"en": "There."})
	elsewhere.add_connection(
		NodeConnection.create(
			elsewhere.get_root().get_id(), "root", there.get_id(), "sentence"
		)
	)

	assert_bool(_load()).is_true()
	_runtime.start()
	assert_int(int(_runtime.get_var("gold", -1))).is_equal(7)

	_runtime.go_to(elsewhere.id)

	assert_array(_player.said).override_failure_message(
		"The move did not land in the section it named."
	).is_equal(["Held.", "There."])
	assert_int(int(_runtime.get_var("gold", -1))).override_failure_message(
		"Moving inside the playthrough lost what it had picked up."
	).is_equal(7)

	_runtime.start(elsewhere.id)

	assert_int(int(_runtime.get_var("gold", -1))).override_failure_message(
		"Starting a new playthrough kept what the last one had."
	).is_equal(0)
