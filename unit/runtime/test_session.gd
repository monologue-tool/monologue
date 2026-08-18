extends GdUnitTestSuite

## Playing a story with nobody watching.
##
## The stories here are built with the editor, written to disk and read back by the addon,
## because that round trip is the thing being tested. A whole playthrough is one `play()`:
## nothing holds the story, so the machine runs to the end inside that call without a frame
## ever passing. What does hold it is pumped by hand with `advance()`.

var _project: MonologueProject
var _path: String
var _player: ScriptedPlayer


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_path = "%s/session_%d.mnlp" % [create_temp_dir("mnlp"), randi()]
	_project = auto_free(MonologueProject.new())
	await _project.ready
	_player = ScriptedPlayer.new()
	add_child(_player)


func after_test() -> void:
	MonologueRegistry.reset_instance()


func _storyline() -> StorylineDocument:
	return _project.storylines[0]


func _node_of_type(type_name: String) -> InspectableNode:
	for node: InspectableNode in _storyline().nodes:
		if node.get_type() == type_name:
			return node
	return null


func _session() -> MonologueSession:
	ProjectWriter.write_project(_project, _path)
	var graph: MonologueStoryGraph = MonologueStoryGraph.of(MonologueSource.open(_path))
	return auto_free(MonologueSession.new(graph, _player, "en"))


## Strips the default storyline to a straight line: root -> sentence -> end.
func _make_linear_story() -> void:
	var storyline: StorylineDocument = _storyline()
	for node: InspectableNode in storyline.nodes.duplicate():
		if node.get_type() in ["choice", "option"]:
			storyline.remove_node(node)

	var sentence: InspectableNode = _node_of_type("sentence")
	sentence.get_property("line").set_value({"en": "Hello."})
	var ending: InspectableNode = storyline.create_node("end")
	storyline.add_connection(
		NodeConnection.create(sentence.get_id(), "sentence", ending.get_id(), "end")
	)


func test_a_straight_story_runs_to_its_end() -> void:
	_make_linear_story()
	var characters: Array = _project.get_collection_value("characters")
	_node_of_type("sentence").get_property("speaker").set_value(str(characters[0]["id"]))

	var seen: Array[String] = []
	var session: MonologueSession = _session()
	session.node_entered.connect(
		func(_storyline_id: String, node_id: String) -> void: seen.append(node_id)
	)

	session.play()

	assert_array(_player.said).is_equal(["Hello."])
	assert_array(_player.speakers).is_equal(["Narrator"])
	assert_str(str(session.state.ending["reason"])).is_equal("behaviour_stopped")
	assert_bool(session.is_running()).is_false()

	# The hook the peering link highlights the active node through.
	assert_str(seen[0]).is_equal(_node_of_type("root").get_id())
	assert_array(seen).contains([_node_of_type("sentence").get_id()])
	# And what a save has to remember about where the story has been.
	assert_int(session.state.times_visited(_node_of_type("sentence").get_id())).is_equal(1)
	assert_int(session.state.step_index).is_greater(0)


func test_a_type_nobody_watches_is_walked_past_and_a_line_nobody_speaks_is_narration() -> void:
	_make_linear_story()
	var storyline: StorylineDocument = _storyline()
	var root: InspectableNode = _node_of_type("root")
	var sentence: InspectableNode = _node_of_type("sentence")
	var bend: InspectableNode = storyline.create_node("reroute")

	for wire: NodeConnection in storyline.get_outgoing(root.get_id()):
		storyline.remove_connection(wire)
	storyline.add_connection(
		NodeConnection.create(root.get_id(), "root", bend.get_id(), "reroute")
	)
	storyline.add_connection(
		NodeConnection.create(bend.get_id(), "reroute", sentence.get_id(), "sentence")
	)

	_session().play()

	assert_array(_player.said).is_equal(["Hello."])
	assert_str(_player.speakers[0]).is_empty()


func test_a_node_can_hold_the_story_until_time_has_passed() -> void:
	# What the machine is for: `wait` keeps the cursor where it is and is ticked, so nothing
	# blocks and a test decides how fast time goes.
	_make_linear_story()
	var storyline: StorylineDocument = _storyline()
	var sentence: InspectableNode = _node_of_type("sentence")
	var pause: InspectableNode = storyline.create_node("wait")
	pause.get_property("seconds").set_value(2.5)

	for wire: NodeConnection in storyline.get_outgoing(sentence.get_id()):
		storyline.remove_connection(wire)
	storyline.add_connection(
		NodeConnection.create(sentence.get_id(), "sentence", pause.get_id(), "wait")
	)

	var session: MonologueSession = _session()
	session.play()

	assert_array(_player.said).is_equal(["Hello."])
	assert_bool(session.is_busy()).is_true()
	assert_str(session.state.current_node()).is_equal(pause.get_id())

	session.advance(1.0)
	assert_bool(session.is_busy()).is_true()

	session.advance(2.0)
	assert_bool(session.is_running()).is_false()


func test_a_story_can_start_anywhere_and_says_so_when_it_cannot() -> void:
	# What "run from here" needs: starting elsewhere is a fresh run with a different first
	# cursor, not a machine resumed in the middle.
	_make_linear_story()
	var ending: InspectableNode = _node_of_type("end")
	var elsewhere: MonologueSession = _session()

	elsewhere.play(_storyline().id, ending.get_id())

	assert_array(_player.said).is_empty()
	assert_str(str(elsewhere.state.ending["reason"])).is_equal("behaviour_stopped")

	var nowhere: MonologueSession = _session()
	nowhere.play(_storyline().id, "sentence-GONE")

	assert_bool(nowhere.has_errors()).is_true()
	assert_str(str(nowhere.state.ending["reason"])).is_equal("error")

	_storyline().remove_node(_node_of_type("root"))
	var rootless: MonologueSession = _session()
	rootless.play()

	assert_bool(rootless.has_errors()).is_true()


func test_a_chain_that_runs_out_ends_and_one_that_loops_is_reported_not_hung() -> void:
	var storyline: StorylineDocument = _storyline()
	for node: InspectableNode in storyline.nodes.duplicate():
		if node.get_type() in ["choice", "option"]:
			storyline.remove_node(node)

	var ran_out: MonologueSession = _session()
	ran_out.play()
	assert_str(str(ran_out.state.ending["reason"])).is_equal("story_ran_out")

	# Nothing in reroute -> reroute -> reroute takes any time, so without a bound the game
	# freezes rather than saying anything.
	for node: InspectableNode in storyline.nodes.duplicate():
		if node.get_type() != "root":
			storyline.remove_node(node)
	var root: InspectableNode = _node_of_type("root")
	var first: InspectableNode = storyline.create_node("reroute")
	var second: InspectableNode = storyline.create_node("reroute")
	storyline.add_connection(
		NodeConnection.create(root.get_id(), "root", first.get_id(), "reroute")
	)
	storyline.add_connection(
		NodeConnection.create(first.get_id(), "reroute", second.get_id(), "reroute")
	)
	storyline.add_connection(
		NodeConnection.create(second.get_id(), "reroute", first.get_id(), "reroute")
	)

	var looping: MonologueSession = _session()
	looping.play()

	assert_str(str(looping.state.ending["code"])).is_equal("story_is_stuck")


func test_a_run_starts_from_the_project_and_can_be_put_back_where_it_was() -> void:
	# Loading a save and the peering rewind are the same operation.
	var variables: CollectionDocument = _project.get_collection("variables")
	var item: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		"variables", _project.command_manager
	)
	item.set_property_value("name", "gold")
	item.set_property_value("type", "int")
	item.set_property_value("value", 7)
	variables.get_property("variables").set_value([item._to_dict()])
	_make_linear_story()

	var session: MonologueSession = _session()
	session.play()

	assert_int(int(session.state.variables[str(item.get_property_value("id"))])).is_equal(7)

	var finished_at: Dictionary = session.snapshot()
	session.restore(finished_at)

	assert_str(session.state.current_node()).is_equal(_node_of_type("end").get_id())
	assert_int(session.state.times_visited(_node_of_type("sentence").get_id())).is_equal(1)


func test_a_line_holds_the_story_until_the_game_answers() -> void:
	# The shape every talking node has: show in run(), leave in input(). Frames alone must
	# not move it, or a reader would never get to read.
	_make_linear_story()
	_player.silent = true
	var sentence: InspectableNode = _node_of_type("sentence")

	var session: MonologueSession = _session()
	session.play()

	assert_array(_player.said).is_equal(["Hello."])
	assert_bool(session.is_busy()).is_true()

	session.advance(1.0)
	assert_str(session.state.current_node()).override_failure_message(
		"A frame moved the story past a line nobody had answered."
	).is_equal(sentence.get_id())

	_player.answer_now()
	session.advance(0.0)

	assert_bool(session.is_running()).is_false()


func test_an_answer_belongs_to_whoever_asked_for_it() -> void:
	# A click landing on a line still on screen while some other node holds the story is not
	# an answer to that node, and must not read as one.
	var relayed: Array[bool] = []
	_player.answered.connect(func() -> void: relayed.append(true))

	_player.answer_now()
	assert_array(relayed).override_failure_message(
		"The player answered a question nobody asked."
	).is_empty()

	_player.say("Hello.")
	assert_int(relayed.size()).is_equal(1)

	_player.answer_now()
	assert_int(relayed.size()).override_failure_message(
		"One question was answered twice."
	).is_equal(1)


func test_a_choice_offers_what_is_stored_and_what_is_wired_in() -> void:
	# The default project ships a choice with an option of its own and an option node wired
	# into its list. A behaviour reads both the same way and leaves by the one taken.
	var storyline: StorylineDocument = _storyline()
	var choice: InspectableNode = _node_of_type("choice")
	var option_node: InspectableNode = _node_of_type("option")
	var stored: String = str((choice.get_property_value("choices") as Array)[0]["id"])
	var external: String = MonologueStoryGraph.EXTERNAL_PREFIX + option_node.get_id()

	var after_stored: InspectableNode = storyline.create_node("end")
	var after_external: InspectableNode = storyline.create_node("end")
	storyline.add_connection(
		NodeConnection.create(choice.get_id(), "choices", after_stored.get_id(), "end", stored)
	)
	storyline.add_connection(
		NodeConnection.create(choice.get_id(), "choices", after_external.get_id(), "end", external)
	)
	_player.answers.append(external)

	var session: MonologueSession = _session()
	session.play()

	assert_array(_player.offered[0]).override_failure_message(
		"A wired option node was not offered alongside the stored ones."
	).contains([stored, external])
	assert_str(session.state.current_node()).override_failure_message(
		"The answer did not leave by its own sub-port."
	).is_equal(after_external.get_id())


func test_the_indexer_finds_the_shipped_behaviours_and_walks_past_the_rest() -> void:
	# Adding a node type is dropping a file in a folder; nothing declares it anywhere.
	var indexer: MonologueBehaviourIndexer = auto_free(MonologueBehaviourIndexer.new())

	assert_array(indexer.names()).contains(["sentence", "wait", "end"])
	assert_int(indexer.all().size()).is_equal(indexer.names().size())

	assert_bool(indexer.has("hologram")).is_false()
	assert_bool(indexer.for_type("hologram") is MonologuePathThroughBehaviour).is_true()


func test_no_behaviour_reaches_for_a_clock_an_input_or_the_tree() -> void:
	# The rule that keeps a headless test from hanging, and the one that makes a behaviour
	# translatable: time arrives as a delta and everything else through the player.
	var forbidden: Dictionary = {
		"get_tree": r"\bget_tree\b",
		"Input": r"(?<![A-Za-z0-9_.])Input\.",
		"Time": r"(?<![A-Za-z0-9_.])Time\.",
		"OS": r"(?<![A-Za-z0-9_.])OS\.",
	}
	var folder: String = MonologueBehaviourIndexer.BUILT_IN_FOLDER
	var checked: int = 0

	for file_name: String in DirAccess.get_files_at(folder):
		if file_name.get_extension() != "gd":
			continue
		checked += 1
		var source: String = FileAccess.get_file_as_string(folder.path_join(file_name))
		assert_str(source).is_not_empty()

		for label: String in forbidden:
			assert_object(
				RegEx.create_from_string(forbidden[label]).search(source)
			).override_failure_message(
				"'%s' reaches for %s; that belongs to the player." % [file_name, label]
			).is_null()

	assert_int(checked).override_failure_message(
		"No behaviour was scanned, so this proves nothing."
	).is_greater(3)
