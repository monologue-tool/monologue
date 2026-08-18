extends GdUnitTestSuite

## Somebody else's node type, running in a story, without a line of the addon changing.
##
## This is the property the whole design exists for. A behaviour is handed its data, its
## wires and the graph, and answers where the story goes; nothing about it is declared to the
## runtime in advance.


## Looks up another node by a name written on it -- the thing a jump does -- entirely on its
## own, and reports its own problem when it cannot.
class ChapterBehaviour extends MonologueBehaviour:
	func handles() -> PackedStringArray:
		return ["chapter"]

	func run(ctx: MonologueContext) -> BehaviourResult:
		var wanted: String = str(ctx.value("go_to_chapter", ""))
		if wanted.is_empty():
			return BehaviourResult.progress(ctx.next("chapter_out"))

		var found: PackedStringArray = ctx.graph.find_by(ctx.storyline, "title", wanted)
		if found.is_empty():
			ctx.fault(&"unknown_chapter", "No chapter is called '%s'." % wanted)
			return BehaviourResult.stop()
		return BehaviourResult.progress(found[0])


## Holds the story until the game answers, exactly as the shipped types do: show in run(),
## leave in input().
class ShoutBehaviour extends MonologueBehaviour:
	func handles() -> PackedStringArray:
		return ["shout"]

	func run(ctx: MonologueContext) -> BehaviourResult:
		ctx.player.say(ctx.text("shout").to_upper())
		return BehaviourResult.wait()

	func input(ctx: MonologueContext) -> BehaviourResult:
		return BehaviourResult.progress(ctx.next())


## Claims no type at all: it only watches, which is what every behaviour may do while
## another one holds the story.
class NoseyBehaviour extends MonologueBehaviour:
	var seen: Array[String] = []
	var ticks: int = 0

	func need_active_process() -> bool:
		return true

	func handles() -> PackedStringArray:
		return []

	func run(_ctx: MonologueContext) -> BehaviourResult:
		return BehaviourResult.wait()

	func step(ctx: MonologueContext) -> BehaviourResult:
		seen.append(ctx.type)
		return BehaviourResult.wait()

	func process(_ctx: MonologueContext, _delta: float) -> BehaviourResult:
		ticks += 1
		return BehaviourResult.wait()


## Sends the story somewhere else before a node it dislikes ever runs.
class HijackBehaviour extends MonologueBehaviour:
	func handles() -> PackedStringArray:
		return []

	func run(_ctx: MonologueContext) -> BehaviourResult:
		return BehaviourResult.wait()

	func step(ctx: MonologueContext) -> BehaviourResult:
		if ctx.id == "shout-1":
			return BehaviourResult.progress("shout-2")
		return BehaviourResult.wait()


var _player: ScriptedPlayer
var _nosey: NoseyBehaviour


func before_test() -> void:
	_player = ScriptedPlayer.new()
	add_child(_player)
	_nosey = NoseyBehaviour.new()


func _indexer() -> MonologueBehaviourIndexer:
	var behaviours: MonologueBehaviourIndexer = MonologueBehaviourIndexer.new()
	behaviours.declare(ChapterBehaviour.new())
	behaviours.declare(ShoutBehaviour.new())
	behaviours.declare(_nosey)
	return behaviours


func _session(nodes: Array, connections: Array) -> MonologueSession:
	var graph: MonologueStoryGraph = MonologueStoryGraph.of(
		MonologueSource.of({
			"manifest.mnlf": {"$type": "manifest", "id": "m-1", "entry_point": "s-1"},
			"storylines/main.mnlf": {
				"$type": "storyline",
				"id": "s-1",
				"root_node_id": "root-1",
				"nodes": nodes,
				"connections": connections,
			},
		})
	)
	return auto_free(MonologueSession.new(graph, _player, "en", _indexer()))


static func _wire(
	from_node: String, from_property: String, to_node: String, to_property: String
) -> Dictionary:
	return {
		"from_node_id": from_node, "from_property": from_property,
		"to_node_id": to_node, "to_property": to_property,
	}


func test_an_unknown_type_can_route_the_story_itself() -> void:
	var session: MonologueSession = _session(
		[
			{"$type": "root", "id": "root-1"},
			{"$type": "chapter", "id": "chapter-1", "go_to_chapter": "The Cellar"},
			{"$type": "chapter", "id": "chapter-2", "title": "The Cellar"},
			{"$type": "shout", "id": "shout-1", "shout": {"en": "hello"}},
		],
		[
			_wire("root-1", "root", "chapter-1", "chapter"),
			_wire("chapter-2", "chapter_out", "shout-1", "shout"),
		]
	)

	session.play()

	# root -> chapter-1, which found chapter-2 by name, which led to the shout.
	assert_array(_player.said).is_equal(["HELLO"])
	assert_int(session.state.times_visited("chapter-2")).is_equal(1)


func test_an_unknown_type_reports_its_own_problems() -> void:
	var session: MonologueSession = _session(
		[
			{"$type": "root", "id": "root-1"},
			{"$type": "chapter", "id": "chapter-1", "go_to_chapter": "Nowhere"},
		],
		[_wire("root-1", "root", "chapter-1", "chapter")]
	)

	session.play()

	var codes: PackedStringArray = []
	for problem: MonologueProblem in session.problems:
		codes.append(String(problem.code))
	assert_array(codes).contains(["unknown_chapter"])


func test_a_type_nobody_claimed_is_walked_past() -> void:
	var session: MonologueSession = _session(
		[
			{"$type": "root", "id": "root-1"},
			{"$type": "hologram", "id": "holo-1"},
			{"$type": "shout", "id": "shout-1", "shout": {"en": "still here"}},
		],
		[
			_wire("root-1", "root", "holo-1", "hologram"),
			_wire("holo-1", "hologram", "shout-1", "shout"),
		]
	)

	session.play()

	assert_array(_player.said).is_equal(["STILL HERE"])


func test_every_behaviour_hears_about_every_node() -> void:
	var session: MonologueSession = _session(
		[
			{"$type": "root", "id": "root-1"},
			{"$type": "shout", "id": "shout-1", "shout": {"en": "listen"}},
		],
		[_wire("root-1", "root", "shout-1", "shout")]
	)

	session.play()

	assert_array(_nosey.seen).is_equal(["root", "shout"])


func test_a_behaviour_that_claims_nothing_can_still_take_the_story_over() -> void:
	# An interrupt, a debug jump, an event watching a variable: all the same hook.
	var session: MonologueSession = _session(
		[
			{"$type": "root", "id": "root-1"},
			{"$type": "shout", "id": "shout-1", "shout": {"en": "never said"}},
			{"$type": "shout", "id": "shout-2", "shout": {"en": "said instead"}},
		],
		[_wire("root-1", "root", "shout-1", "shout")]
	)
	session.behaviours.declare(HijackBehaviour.new())

	session.play()

	assert_array(_player.said).is_equal(["SAID INSTEAD"])
