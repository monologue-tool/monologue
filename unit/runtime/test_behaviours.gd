extends GdUnitTestSuite

## What each node type does when the story reaches it.
##
## Built with the editor, written to disk and read back by the addon. A behaviour reading a
## property the editor does not write is the mistake worth catching, and only the round trip
## catches it.

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
	return _storyline.get_root()


## By each end's own flow port, which a node type names after itself.
func _wire(from_node: InspectableNode, to_node: InspectableNode, from_port: String = "") -> void:
	_wire_in(_storyline, from_node, to_node, from_port)


## The same, inside a section rather than in the storyline every case starts from.
func _wire_in(
	document: StorylineDocument,
	from_node: InspectableNode,
	to_node: InspectableNode,
	from_port: String = ""
) -> void:
	document.add_connection(
		NodeConnection.create(
			from_node.get_id(),
			from_port if not from_port.is_empty() else from_node.get_type(),
			to_node.get_id(),
			to_node.get_type()
		)
	)


func _first_record(collection_name: String) -> String:
	var records: Array = _project.get_collection_value(collection_name)
	return str((records[0] as Dictionary).get("id", "")) if not records.is_empty() else ""


## The default portrait is the one a node naming none falls back to.
func _give_a_portrait(character_id: String, image: String) -> void:
	var records: Array = _project.get_collection_value("characters").duplicate(true)
	for record: Dictionary in records:
		if str(record.get("id", "")) != character_id:
			continue
		for portrait: Variant in record.get("portraits", []):
			if portrait is Dictionary:
				(portrait as Dictionary)["image"] = image

	_project.get_collection("characters").get_property("characters").set_value(records)


func _ease_named(ease_name: String) -> String:
	for record: Variant in _project.get_collection_value("eases"):
		if record is Dictionary and str(record.get("name", "")) == ease_name:
			return str(record.get("id", ""))
	return ""


func _add_record(collection_name: String, values: Dictionary) -> String:
	var item: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		collection_name, _project.command_manager
	)
	for property_name: String in values:
		item.set_property_value(property_name, values[property_name])

	var document: CollectionDocument = _project.get_collection(collection_name)
	var records: Array = document.get_value().duplicate(true)
	records.append(item._to_dict())
	document.set_property_value(collection_name, records)
	return str(item.get_property_value("id"))


func _declare_variable(variable_name: String, type_name: String, initial: Variant) -> String:
	return _add_record(
		"variables", {"name": variable_name, "type": type_name, "value": initial}
	)


func _play() -> MonologueSession:
	ProjectWriter.write_project(_project, _path)
	var graph: MonologueStoryGraph = MonologueStoryGraph.of(MonologueSource.open(_path))
	var session: MonologueSession = auto_free(MonologueSession.new(graph, _player, "en"))
	session.play()
	return session


func test_a_variable_is_written_then_read_by_the_branch_that_follows() -> void:
	# The pair that turns a story into a program. One node writes, the next one asks.
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


func test_a_jump_leaves_for_good_where_a_section_would_come_back() -> void:
	# Both land at a section root. Only one leaves an address behind.
	var elsewhere: StorylineDocument = _project.add_section(_storyline.id, "elsewhere")
	var there: InspectableNode = elsewhere.create_node("sentence")
	there.get_property("line").set_value({"en": "There."})
	_wire_in(elsewhere, elsewhere.get_root(), there)

	var leap: InspectableNode = _node("jump")
	leap.get_property("target").set_value(elsewhere.id)
	_wire(_root(), leap)

	var session: MonologueSession = _play()

	assert_array(_player.said).override_failure_message(
		"The jump did not land in the section it names."
	).is_equal(["There."])
	assert_array(session.state.call_stack).override_failure_message(
		"A jump left somewhere to come back to, which only a section does."
	).is_empty()
	assert_bool(session.has_errors()).is_false()


func test_a_jump_that_names_nothing_says_so_rather_than_wandering_off() -> void:
	var leap: InspectableNode = _node("jump")
	leap.get_property("target").set_value("storyline-GONE")
	_wire(_root(), leap)

	var session: MonologueSession = _play()

	var codes: PackedStringArray = []
	for problem: MonologueProblem in session.problems:
		codes.append(String(problem.code))
	assert_array(codes).contains(["unknown_section"])


func test_the_inventory_counts_what_the_story_gave_and_took() -> void:
	# What one character is given is not in anybody else's pockets.
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
	assert_bool(_player.acted[0]["waited"]).override_failure_message(
		"A plain action held the story instead of carrying on."
	).is_false()


func test_an_action_can_wait_for_the_game_and_keep_what_it_answers() -> void:
	# The shape every other tool has for reaching out of a story and getting something back.
	var score: String = _declare_variable("score", "int", 0)

	var play: InspectableNode = _node("action")
	play.get_property("name").set_value("play_minigame")
	play.get_property("wait").set_value(true)
	play.get_property("result").set_value(score)

	var after: InspectableNode = _node("sentence")
	after.get_property("line").set_value({"en": "Done."})

	_wire(_root(), play)
	_wire(play, after)
	_player.action_answers = [7]

	var session: MonologueSession = _play()

	assert_bool(_player.acted[0]["waited"]).override_failure_message(
		"The action did not tell the game the story was waiting on it."
	).is_true()
	assert_int(int(session.state.variables[score])).override_failure_message(
		"What the game answered was not kept."
	).is_equal(7)
	assert_array(_player.said).override_failure_message(
		"The story did not carry on after the game answered."
	).is_equal(["Done."])


func test_a_section_runs_and_comes_back_by_the_way_it_stopped() -> void:
	# One exit per place the section's chain stops, keyed by the node it stopped at.
	var detour: StorylineDocument = _project.add_section(_storyline.id, "detour")
	var body: InspectableNode = detour.create_node("sentence")
	body.get_property("line").set_value({"en": "Inside."})
	_wire_in(detour, detour.get_root(), body)

	var after: InspectableNode = _node("sentence")
	after.get_property("line").set_value({"en": "Back."})

	var runs: InspectableNode = _node("section")
	runs.get_property("target").set_value(detour.id)

	_wire(_root(), runs)
	_storyline.add_connection(
		NodeConnection.create(
			runs.get_id(),
			"exits",
			after.get_id(),
			"sentence",
			MonologueStoryGraph.EXTERNAL_PREFIX + body.get_id()
		)
	)

	var session: MonologueSession = _play()

	assert_array(_player.said).override_failure_message(
		"The section did not run, or did not come back by the exit it stopped at."
	).is_equal(["Inside.", "Back."])
	assert_array(session.state.call_stack).override_failure_message(
		"The return address was left on the stack."
	).is_empty()


func test_a_section_that_runs_itself_is_stopped_rather_than_left_to_spin() -> void:
	var loop: StorylineDocument = _project.add_section(_storyline.id, "loop")
	var again: InspectableNode = loop.create_node("section")
	again.get_property("target").set_value(loop.id)
	_wire_in(loop, loop.get_root(), again)

	var enters: InspectableNode = _node("section")
	enters.get_property("target").set_value(loop.id)
	_wire(_root(), enters)

	var session: MonologueSession = _play()

	var codes: PackedStringArray = []
	for problem: MonologueProblem in session.problems:
		codes.append(String(problem.code))
	assert_array(codes).override_failure_message(
		"A section running itself was not stopped: %s" % str(codes)
	).contains(["section_too_deep"])


func test_an_event_takes_over_once_its_variable_matches() -> void:
	# An event answers between two nodes, so the line setting the variable is read first.
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

	# Pointed at its own storyline, so it restarts it, and the loop guard is what stops it
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
	# The state keeps what is on screen, so the picture comes back without replaying.
	var cast: String = _first_record("characters")

	# Everything is written relative to where the art is kept, and all three stage nodes go
	# through the same resolution.
	_player.asset_root = "art"
	_give_a_portrait(cast, "faces/day.png")

	var scenery: InspectableNode = _node("background")
	scenery.get_property("image").set_value("room.png")

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

	assert_str(str(look["image"])).override_failure_message(
		"The part was handed a stored path rather than somewhere it could open."
	).is_equal("art/faces/day.png")

	assert_int(_player.audio.played.size()).is_equal(1)
	assert_bool(_player.audio.played[0]["loop"]).is_true()
	assert_str(str(_player.audio.played[0]["path"])).override_failure_message(
		"A sound was handed over as the story wrote it rather than as somewhere to open."
	).is_equal("art/sound/theme.ogg")

	# The other half. What is kept is what the story wrote, not where it was found.
	assert_str(str(session.state.stage.get("background", ""))).override_failure_message(
		"An absolute path was baked into the save."
	).is_equal("room.png")
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

	var session: MonologueSession = _play()
	var saved: Dictionary = session.snapshot()

	# The save keeps the path the story wrote, so it still finds its art on another machine.
	var kept: Dictionary = session.state.stage["characters"][cast]
	assert_bool(kept.has("image")).override_failure_message(
		"An absolute path was baked into the save."
	).is_false()

	# A second session is handed the save and rebuilds the stage from what the state
	# remembers.
	var reader: ScriptedPlayer = ScriptedPlayer.new()
	add_child(reader)
	var graph: MonologueStoryGraph = MonologueStoryGraph.of(MonologueSource.open(_path))
	var reading: MonologueSession = auto_free(MonologueSession.new(graph, reader, "en"))
	reading.restore(saved)
	reading.resume_here()

	assert_array(reader.backdrop.images).contains(["art/room.png"])
	assert_dict(reader.staged.restaged).contains_keys([cast])
	assert_int(reader.audio.played.size()).override_failure_message(
		"The music that was still playing did not start again."
	).is_equal(1)


func test_a_location_moves_the_story_and_puts_the_place_on_screen() -> void:
	var place: String = _add_record("locations", {
		"name": "Tavern",
		"variations": [
			{"id": "variation-DAY", "name": "day", "image": "art/day.png", "is_default": true},
			{"id": "variation-NIGHT", "name": "night", "image": "art/night.png"},
		],
	})

	var dusk: InspectableNode = _node("location")
	dusk.get_property("target").set_value(place)
	dusk.get_property("variation").set_value("variation-NIGHT")

	var dawn: InspectableNode = _node("location")
	dawn.get_property("target").set_value(place)

	var elsewhere: InspectableNode = _node("location")
	elsewhere.get_property("target").set_value(place)
	elsewhere.get_property("show_image").set_value(false)

	_wire(_root(), dusk)
	_wire(dusk, dawn)
	_wire(dawn, elsewhere)

	var session: MonologueSession = _play()

	assert_array(_player.backdrop.images).override_failure_message(
		"The named variation did not come up, the default did not stand in for the one nobody"
		+ " named, or a node told not to show a picture showed one."
	).is_equal(["art/night.png", "art/day.png"])

	var here: Dictionary = session.state.stage["location"]
	assert_str(str(here["location"])).is_equal(place)
	assert_str(str(session.state.stage["background"])).override_failure_message(
		"A place and a background node do not share the one thing behind everyone."
	).is_equal("art/day.png")
