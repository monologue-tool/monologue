extends GdUnitTestSuite

## What a game sees of Monologue: one node, four verbs, and a way to reach its own things
## from inside a story.
##
## The cases here are the ones a game that is not only a story runs into -- a run that ends
## so gameplay can resume, a run paused while something else happens over it, a story node
## that has to reach the inventory. A pure visual novel is the easy subset of this.


## A node type of the game's own that reaches a service the addon has never heard of.
class SpendBehaviour extends MonologueBehaviour:
	func handles() -> PackedStringArray:
		return ["action"]

	func run(ctx: MonologueContext) -> BehaviourResult:
		var purse: Object = ctx.service("purse")
		if purse:
			purse.call(&"spend", 3)
		return BehaviourResult.progress(ctx.next())


## Not a MonologueService at all: any object a behaviour can call is a legal service.
class Purse extends RefCounted:
	var coins: int = 10

	func spend(amount: int) -> void:
		coins -= amount

	func save_state() -> Dictionary:
		return {"coins": coins}

	func load_state(data: Dictionary) -> void:
		coins = int(data.get("coins", 0))


var _project: MonologueProject
var _path: String
var _runtime: MonologueRuntime


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_path = "%s/facade_%d.mnlp" % [create_temp_dir("mnlp"), randi()]
	_project = auto_free(MonologueProject.new())
	await _project.ready
	_runtime = MonologueRuntime.new()
	add_child(_runtime)


func after_test() -> void:
	_runtime.queue_free()
	MonologueRegistry.reset_instance()


func _storyline() -> StorylineDocument:
	return _project.storylines[0]


func _node_of_type(type_name: String) -> InspectableNode:
	for node: InspectableNode in _storyline().nodes:
		if node.get_type() == type_name:
			return node
	return null


## root -> sentence -> end, with the branching the default project ships stripped out.
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


func _load() -> bool:
	ProjectWriter.write_project(_project, _path)
	return _runtime.load_project(_path)


func test_a_game_loads_a_project_plays_it_and_is_told_when_it_is_over() -> void:
	_make_linear_story()
	assert_bool(_load()).is_true()

	var began: Array[String] = []
	var ended: Array[String] = []
	_runtime.story_started.connect(func(id: String) -> void: began.append(id))
	_runtime.story_ended.connect(func(reason: String) -> void: ended.append(reason))

	assert_bool(_runtime.is_idle()).is_true()

	_runtime.start()

	# Nothing holds this story, so it is over inside start() -- and it was announced as
	# beginning before it was announced as ending.
	assert_int(began.size()).is_equal(1)
	assert_int(ended.size()).is_equal(1)
	assert_bool(_runtime.is_idle()).override_failure_message(
		"The runtime should be idle again, ready for the next scene."
	).is_true()
	assert_str(String(_runtime.activity())).is_empty()


func test_a_story_can_be_held_while_something_else_happens_over_it() -> void:
	# The gameplay-phase case: a story sitting on a node stays exactly there.
	_make_linear_story()
	var storyline: StorylineDocument = _storyline()
	var sentence: InspectableNode = _node_of_type("sentence")
	var pause_node: InspectableNode = storyline.create_node("wait")
	pause_node.get_property("seconds").set_value(5.0)
	for wire: NodeConnection in storyline.get_outgoing(sentence.get_id()):
		storyline.remove_connection(wire)
	storyline.add_connection(
		NodeConnection.create(sentence.get_id(), "sentence", pause_node.get_id(), "wait")
	)
	assert_bool(_load()).is_true()

	var session: MonologueSession = _runtime.start()

	assert_bool(_runtime.is_idle()).is_false()
	assert_str(String(_runtime.activity())).is_equal("wait")

	_runtime.pause()
	session.advance(10.0)

	assert_bool(_runtime.is_paused()).is_true()
	assert_str(session.state.current_node()).override_failure_message(
		"A paused story kept counting."
	).is_equal(pause_node.get_id())

	_runtime.resume()
	session.advance(10.0)

	assert_bool(_runtime.is_idle()).is_true()


func test_a_story_node_reaches_something_the_addon_has_never_heard_of() -> void:
	_make_linear_story()
	var storyline: StorylineDocument = _storyline()
	var sentence: InspectableNode = _node_of_type("sentence")
	var spend: InspectableNode = storyline.create_node("action")
	for wire: NodeConnection in storyline.get_outgoing(sentence.get_id()):
		storyline.remove_connection(wire)
	storyline.add_connection(
		NodeConnection.create(sentence.get_id(), "sentence", spend.get_id(), "action")
	)
	assert_bool(_load()).is_true()

	var purse: Purse = Purse.new()
	_runtime.provide("purse", purse)
	_runtime.behaviours.declare(SpendBehaviour.new())

	_runtime.start()

	assert_int(purse.coins).override_failure_message(
		"The behaviour did not reach the service the game provided."
	).is_equal(7)


func test_a_save_carries_the_story_and_everything_the_services_kept() -> void:
	_make_linear_story()
	assert_bool(_load()).is_true()
	var purse: Purse = Purse.new()
	_runtime.provide("purse", purse)

	_runtime.start()
	purse.spend(4)
	var saved: Dictionary = _runtime.save()

	assert_bool((saved["story"] as Dictionary).is_empty()).is_false()
	assert_int(int((saved["services"] as Dictionary)["purse"]["coins"])).is_equal(6)

	purse.coins = 999
	_runtime.restore(saved)

	assert_int(purse.coins).is_equal(6)


func test_a_project_that_has_never_been_saved_can_be_played() -> void:
	# What the editor's Run button rides on: the live documents go straight into the addon,
	# so what plays is the unsaved edit rather than the last thing written to disk.
	_make_linear_story()
	_node_of_type("sentence").get_property("line").set_value({"en": "Not on disk."})

	assert_bool(_runtime.load_documents(ProjectWriter.documents_of(_project))).is_true()
	_runtime.start()

	assert_bool(FileAccess.file_exists(_path)).override_failure_message(
		"Running wrote the project out; it is meant to stay in memory."
	).is_false()
	assert_bool(_runtime.is_idle()).is_true()


func test_the_shipped_history_service_is_there_without_anyone_asking() -> void:
	# Proves the service folder is scanned at all, and that a service survives a run so a
	# game alternating story and gameplay keeps what it gathered.
	var history: Object = _runtime.service("history")

	assert_object(history).is_not_null()
	assert_array(_runtime.services.names()).contains(["history"])

	history.call(&"record", "Hello.", "Narrator", "sentence-1")
	assert_int((history.call(&"last", 1) as Array).size()).is_equal(1)
