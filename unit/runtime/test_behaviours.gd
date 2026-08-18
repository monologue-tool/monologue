extends GdUnitTestSuite

## What each node type does when the story reaches it.
##
## Built with the editor, written to disk and read back by the addon, like every other
## runtime suite: a behaviour reading a property the editor does not write is the mistake
## worth catching, and only the round trip catches it.

var _project: MonologueProject
var _path: String
var _player: ScriptedPlayer
var _storyline: StorylineDocument


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_path = "%s/behaviours_%d.mnlp" % [create_temp_dir("mnlp"), randi()]
	_project = auto_free(MonologueProject.new())
	await _project.ready
	_player = ScriptedPlayer.new()
	add_child(_player)

	# Every case here builds its own chain, so the shipped one is in the way.
	_storyline = _project.storylines[0]
	for node: InspectableNode in _storyline.nodes.duplicate():
		if node.get_type() != "root":
			_storyline.remove_node(node)


func after_test() -> void:
	MonologueRegistry.reset_instance()


func _node(type_name: String) -> InspectableNode:
	return _storyline.create_node(type_name)


func _root() -> InspectableNode:
	for node: InspectableNode in _storyline.nodes:
		if node.get_type() == "root":
			return node
	return null


## Wires by each end's own flow port, which is what a node type names after itself.
func _wire(from_node: InspectableNode, to_node: InspectableNode, from_port: String = "") -> void:
	_storyline.add_connection(
		NodeConnection.create(
			from_node.get_id(),
			from_port if not from_port.is_empty() else from_node.get_type(),
			to_node.get_id(),
			to_node.get_type()
		)
	)


## The id of the first record a collection ships with.
func _first_record(collection_name: String) -> String:
	var records: Array = _project.get_collection_value(collection_name)
	return str((records[0] as Dictionary).get("id", "")) if not records.is_empty() else ""


func _ease_named(ease_name: String) -> String:
	for record: Variant in _project.get_collection_value("eases"):
		if record is Dictionary and str(record.get("name", "")) == ease_name:
			return str(record.get("id", ""))
	return ""


## Declares a variable in the project so the runtime knows what type to coerce it to.
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


func _play() -> MonologueSession:
	ProjectWriter.write_project(_project, _path)
	var graph: MonologueStoryGraph = MonologueStoryGraph.of(MonologueSource.open(_path))
	var session: MonologueSession = auto_free(MonologueSession.new(graph, _player, "en"))
	session.play()
	return session


func test_a_variable_is_written_then_read_by_the_branch_that_follows() -> void:
	# The pair that turns a story into a program: one node writes, the next one asks.
	var gold: String = _declare_variable("gold", "int", 1)

	var give: InspectableNode = _node("variable")
	give.get_property("target").set_value(gold)
	give.get_property("operator").set_value("+")
	give.get_property("value").set_value(4)

	var branch: InspectableNode = _node("condition")
	branch.get_property("test").set_value(
		{"variable": gold, "operator": ">=", "value": 5}
	)

	var rich: InspectableNode = _node("sentence")
	rich.get_property("line").set_value({"en": "Rich."})
	var poor: InspectableNode = _node("sentence")
	poor.get_property("line").set_value({"en": "Poor."})

	_wire(_root(), give)
	_wire(give, branch)
	_wire(branch, rich, "pass")
	_wire(branch, poor, "fail")

	var session: MonologueSession = _play()

	assert_int(int(session.state.variables[gold])).override_failure_message(
		"1 + 4 did not come out as 5."
	).is_equal(5)
	assert_array(_player.said).is_equal(["Rich."])


func test_a_jump_lands_on_the_waypoint_it_names() -> void:
	var waypoint: InspectableNode = _node("waypoint")
	waypoint.get_property("label").set_value("chapter_two")
	var arrived: InspectableNode = _node("sentence")
	arrived.get_property("line").set_value({"en": "Arrived."})
	var skipped: InspectableNode = _node("sentence")
	skipped.get_property("line").set_value({"en": "Skipped."})

	var leap: InspectableNode = _node("jump")
	leap.get_property("waypoint").set_value("chapter_two")

	_wire(_root(), leap)
	_wire(waypoint, arrived)
	_wire(skipped, waypoint)

	var session: MonologueSession = _play()

	assert_array(_player.said).override_failure_message(
		"The jump did not land on its waypoint, or walked through the node before it."
	).is_equal(["Arrived."])
	assert_bool(session.has_errors()).is_false()


func test_a_jump_that_names_nothing_says_so_rather_than_wandering_off() -> void:
	var leap: InspectableNode = _node("jump")
	leap.get_property("waypoint").set_value("nowhere")
	_wire(_root(), leap)

	var session: MonologueSession = _play()

	var codes: PackedStringArray = []
	for problem: MonologueProblem in session.problems:
		codes.append(String(problem.code))
	assert_array(codes).contains(["unknown_waypoint"])


func test_the_inventory_counts_what_the_story_gave_and_took() -> void:
	# Everyone carries their own: what one character is given is not in anybody else's
	# pockets, which is the whole reason the count is filed under a name.
	var cast: String = _first_record("characters")

	var give: InspectableNode = _node("inventory")
	give.get_property("who").set_value(cast)
	give.get_property("item").set_value("item-COIN")
	give.get_property("operation").set_value("Give")
	give.get_property("quantity").set_value(3)

	var take: InspectableNode = _node("inventory")
	take.get_property("who").set_value(cast)
	take.get_property("item").set_value("item-COIN")
	take.get_property("operation").set_value("Take")
	take.get_property("quantity").set_value(5)

	_wire(_root(), give)
	_wire(give, take)

	var session: MonologueSession = _play()

	assert_int(session.state.held(cast, "item-COIN")).override_failure_message(
		"Taking more than was held went negative."
	).is_equal(0)
	assert_int(session.state.held("character-NOBODY", "item-COIN")).override_failure_message(
		"The coin landed in a pile everybody shares."
	).is_equal(0)


func test_an_action_reaches_the_game_with_what_was_written_beside_it() -> void:
	var call_out: InspectableNode = _node("action")
	call_out.get_property("name").set_value("play_cutscene")
	call_out.get_property("arguments").set_value(["intro", "loud"])
	_wire(_root(), call_out)

	_play()

	assert_int(_player.acted.size()).is_equal(1)
	assert_str(str(_player.acted[0]["name"])).is_equal("play_cutscene")
	assert_array(_player.acted[0]["arguments"]).is_equal(["intro", "loud"])


func test_a_call_runs_a_function_and_comes_back_by_the_way_it_stopped() -> void:
	# The exits are not written by hand: one is grown per place the function's chain stops,
	# keyed by the node it stopped at. This is the runtime end of that bargain.
	var entry: InspectableNode = _node("function")
	var body: InspectableNode = _node("sentence")
	body.get_property("line").set_value({"en": "Inside."})
	var after: InspectableNode = _node("sentence")
	after.get_property("line").set_value({"en": "Back."})

	var caller: InspectableNode = _node("call")
	caller.get_property("target").set_value(entry.get_id())

	_wire(_root(), caller)
	_wire(entry, body)
	_storyline.add_connection(
		NodeConnection.create(
			caller.get_id(),
			"exits",
			after.get_id(),
			"sentence",
			MonologueStoryGraph.EXTERNAL_PREFIX + body.get_id()
		)
	)

	var session: MonologueSession = _play()

	assert_array(_player.said).override_failure_message(
		"The call did not run the function, or did not come back by the exit it stopped at."
	).is_equal(["Inside.", "Back."])
	assert_array(session.state.call_stack).override_failure_message(
		"The return address was left on the stack."
	).is_empty()


func test_an_event_takes_over_once_its_variable_matches() -> void:
	# Nothing wires into an event: it is armed for the whole run and answers between two
	# nodes, so the line that set the variable is read before the branch takes over.
	var alarm: String = _declare_variable("alarm", "bool", false)

	var watcher: InspectableNode = _node("event")
	watcher.get_property("test").set_value(
		{"variable": alarm, "operator": "==", "value": true}
	)
	var interrupt: InspectableNode = _node("sentence")
	interrupt.get_property("line").set_value({"en": "Alarm!"})
	_wire(watcher, interrupt)

	var quiet: InspectableNode = _node("sentence")
	quiet.get_property("line").set_value({"en": "Quiet."})
	var trip: InspectableNode = _node("variable")
	trip.get_property("target").set_value(alarm)
	trip.get_property("operator").set_value("=")
	trip.get_property("value").set_value(true)
	var never: InspectableNode = _node("sentence")
	never.get_property("line").set_value({"en": "Never."})

	_wire(_root(), quiet)
	_wire(quiet, trip)
	_wire(trip, never)

	_play()

	assert_array(_player.said).override_failure_message(
		"The event fired at the wrong moment, or not at all."
	).is_equal(["Quiet.", "Alarm!"])


func test_a_storyline_node_leaves_for_another_and_drops_what_it_was_owed() -> void:
	var leave: InspectableNode = _node("storyline")
	leave.get_property("target").set_value(_storyline.id)
	_wire(_root(), leave)
	_storyline.create_node("checkpoint")

	var session: MonologueSession = _play()

	# Pointed at its own storyline, so it restarts it -- and the loop guard is what stops it
	# rather than anything crashing.
	assert_str(str(session.state.ending["code"])).override_failure_message(
		"Leaving for a storyline did not reach its beginning."
	).is_equal("story_is_stuck")


func test_a_checkpoint_records_where_the_story_can_be_picked_up() -> void:
	var mark: InspectableNode = _node("checkpoint")
	var after: InspectableNode = _node("sentence")
	after.get_property("line").set_value({"en": "Onward."})

	_wire(_root(), mark)
	_wire(mark, after)

	var session: MonologueSession = _play()

	assert_str(session.state.checkpoint).is_equal(mark.get_id())
	assert_array(_player.said).is_equal(["Onward."])


func test_asking_the_reader_holds_the_story_and_keeps_the_answer() -> void:
	var who: String = _declare_variable("who", "string", "")

	var prompt: InspectableNode = _node("input")
	prompt.get_property("text").set_value({"en": "Your name?"})
	prompt.get_property("variable").set_value(who)

	var pause: InspectableNode = _node("wait_input")
	_wire(_root(), prompt)
	_wire(prompt, pause)

	_player.answers.append("Alice")
	_player.silent = true
	var session: MonologueSession = _play()

	assert_bool(session.is_busy()).override_failure_message(
		"The prompt did not hold the story."
	).is_true()

	_player.answer_now()
	session.advance(0.0)

	assert_str(str(session.state.variables[who])).is_equal("Alice")
	assert_int(_player.acknowledged).override_failure_message(
		"The story did not reach the node that waits for a press."
	).is_equal(1)

	_player.answer_now()
	session.advance(0.0)

	assert_bool(session.is_running()).is_false()


func test_the_stage_nodes_reach_their_parts_and_leave_the_stage_behind_them() -> void:
	# What is on screen is not a side effect: the state keeps it, so the same picture can be
	# put back later without any of this being replayed.
	var cast: String = _first_record("characters")

	var scenery: InspectableNode = _node("background")
	scenery.get_property("image").set_value("art/room.png")

	var join: InspectableNode = _node("character")
	join.get_property("who").set_value(cast)
	join.get_property("action").set_value("Join")
	join.get_property("position").set_value("Center")
	join.get_property("curve").set_value(_ease_named("Linear"))

	var music: InspectableNode = _node("audio")
	music.get_property("stream").set_value("sound/theme.ogg")
	music.get_property("loop").set_value(true)

	var goodbye: InspectableNode = _node("character")
	goodbye.get_property("who").set_value(cast)
	goodbye.get_property("action").set_value("Leave")

	_wire(_root(), scenery)
	_wire(scenery, join)
	_wire(join, music)
	_wire(music, goodbye)

	var session: MonologueSession = _play()
	assert_array(_player.backdrop.images).is_equal(["art/room.png"])
	assert_array(_player.staged.left).is_equal([cast])
	assert_int(_player.staged.applied.size()).is_equal(1)

	var look: Dictionary = _player.staged.applied[0]["look"]
	assert_str(str(look["position"])).is_equal("Center")
	# Linear ends at 1.0 where the default the project would have fallen back to ends at 0.25.
	var curve: Array = look["curve"]
	assert_int(curve.size()).is_equal(4)
	assert_float(float(curve[2])).override_failure_message(
		"The named ease did not reach the part as its coordinates."
	).is_equal_approx(1.0, 0.001)
	assert_str(str((look["portrait"] as Dictionary).get("name", ""))).override_failure_message(
		"The character's default portrait did not stand in for the one nobody named."
	).is_equal("default")

	assert_int(_player.audio.played.size()).is_equal(1)
	assert_bool(_player.audio.played[0]["loop"]).is_true()

	assert_str(str(session.state.stage.get("background", ""))).is_equal("art/room.png")
	assert_dict(session.state.stage.get("characters", {})).override_failure_message(
		"Leaving did not take the character off the stage."
	).is_empty()


func test_a_restored_save_comes_back_to_the_picture_it_left() -> void:
	var cast: String = _first_record("characters")

	var scenery: InspectableNode = _node("background")
	scenery.get_property("image").set_value("art/room.png")

	var join: InspectableNode = _node("character")
	join.get_property("who").set_value(cast)

	var music: InspectableNode = _node("audio")
	music.get_property("stream").set_value("sound/theme.ogg")
	music.get_property("loop").set_value(true)

	_wire(_root(), scenery)
	_wire(scenery, join)
	_wire(join, music)
	_wire(music, _node("end"))

	var saved: Dictionary = _play().snapshot()

	# Nobody replays anything: a second session is handed the save and has to put the stage
	# together again out of what the state remembers.
	var reader: ScriptedPlayer = ScriptedPlayer.new()
	add_child(reader)
	var graph: MonologueStoryGraph = MonologueStoryGraph.of(MonologueSource.open(_path))
	var session: MonologueSession = auto_free(MonologueSession.new(graph, reader, "en"))
	session.restore(saved)
	session.resume_here()

	assert_array(reader.backdrop.images).contains(["art/room.png"])
	assert_dict(reader.staged.restaged).contains_keys([cast])
	assert_int(reader.audio.played.size()).override_failure_message(
		"The music that was still playing did not start again."
	).is_equal(1)
