## One playthrough, as a state machine ticked once a frame.
##
## Every decision about what a node type means lives in a behaviour. Nothing here names one.
## A node stays current across frames until its behaviour says otherwise, so an animation, a
## line being typed and a menu waiting for a click are all the same to the loop.
class_name MonologueSession extends Node

## A story entering this many nodes in one frame is looping. Counted per frame, so a long
## story is not mistaken for a stuck one.
const MAX_STEPS_PER_FRAME: int = 10000

signal node_entered(storyline_id: String, node_id: String)
signal finished()
signal stepped()

var graph: MonologueStoryGraph
var state: MonologueState = MonologueState.new()
var player: MonologuePlayer
var language: String = ""
var problems: Array[MonologueProblem] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var behaviours: MonologueBehaviourIndexer
## Injected by the runtime so it outlives a single playthrough.
var services: MonologueServiceIndexer

## The story advances one node per [method step_once] rather than freely.
var single_step: bool = false

var _running: bool = false
var _paused: bool = false
## The node the player last answered for. An answer belongs to whoever asked, so one arriving
## after the story has moved on is left where it lies.
var _answered_for: String = ""
## Whether [method MonologueBehaviour.run] has already been called on the node the cursor is
## at. The one bit that makes this a machine and not a loop.
var _busy: bool = false
var _released: bool = false
var _steps_this_frame: int = 0


func _init(
	p_graph: MonologueStoryGraph,
	p_player: MonologuePlayer,
	p_language: String = "",
	p_behaviours: MonologueBehaviourIndexer = null,
	p_services: MonologueServiceIndexer = null
) -> void:
	graph = p_graph
	player = p_player
	language = p_language if not p_language.is_empty() else _default_language()
	problems.append_array(graph.problems)
	behaviours = p_behaviours if p_behaviours != null else MonologueBehaviourIndexer.new(problems)
	if behaviours.get_parent() == null:
		add_child(behaviours)

	services = p_services if p_services != null else MonologueServiceIndexer.new(problems)
	if services.get_parent() == null:
		add_child(services)

	player.answered.connect(_on_answered)


func _process(delta: float) -> void:
	if _running and not _paused:
		advance(delta)


func play(storyline_id: String = "", node_id: String = "") -> void:
	var target: String = storyline_id if not storyline_id.is_empty() else graph.entry_storyline
	var start: String = node_id if not node_id.is_empty() else graph.entry_of(target)
	if not graph.has_node(start):
		_fail(&"no_entry_node", "There is nowhere to start: '%s' is not a node." % start)
		return

	state = MonologueState.new()
	_seed_variables()
	state.move_to(graph.storyline_of(start), start)
	resume_here()


## Carries on from wherever the state says the story is.
##
## Never blocks. Returns as soon as the story settles on a node. A story nothing holds, which
## is everything a headless test plays, runs to its end inside this call.
func resume_here() -> void:
	_running = true
	_busy = false
	_released = false
	_answered_for = ""

	var ctx: MonologueContext = MonologueContext.new(self, "")
	for behaviour: MonologueBehaviour in behaviours.all():
		behaviour.setup(ctx)

	advance(0.0)


## One frame of story, however many nodes that turns out to be. A test with no scene tree
## pumps it by hand to get past anything that counts down.
func advance(delta: float) -> void:
	if _paused:
		return
	_steps_this_frame = 0
	while _running:
		_steps_this_frame += 1
		if _steps_this_frame > MAX_STEPS_PER_FRAME:
			_fail(
				&"story_is_stuck",
				"%d nodes ran in one frame; the story is looping." % MAX_STEPS_PER_FRAME
			)
			return

		if single_step and not _busy and not _released:
			return

		var node_id: String = state.current_node()
		if node_id.is_empty():
			_end(&"story_ran_out")
			return
		if not graph.has_node(node_id):
			_fail(&"unknown_node", "The story points at '%s', which is gone." % node_id)
			return

		var ctx: MonologueContext = MonologueContext.new(self, node_id)
		var result: BehaviourResult = _step(ctx, delta)
		if result == null or result.is_waiting():
			# A player with no parts answers inside run(), so the answer can arrive before the
			# node has finished being entered. Going round again catches it.
			if _answered_for == node_id:
				continue
			return

		_busy = false
		_released = false
		stepped.emit()
		if result.is_stop():
			_end(&"behaviour_stopped")
			return
		_go(result.node)


func step_once() -> void:
	_released = true
	if _running:
		advance(0.0)


func stop() -> void:
	if not _running:
		return
	_busy = false
	_end(&"stopped")


## Loading a save and the peering rewind are the same operation. Call [method resume_here]
## afterwards to carry on. What was on screen comes back there, rebuilt by the behaviours that
## put it up.
func restore(data: Dictionary) -> void:
	_running = false
	_busy = false
	_answered_for = ""
	state = MonologueState.from_dict(data)
	rng.seed = state.rng_seed


func snapshot() -> Dictionary:
	state.rng_seed = rng.seed
	return state.to_dict()


## Freezes the story where it stands without ending it. The behaviour holding the node stops
## being ticked, so a timer stops counting and a line stops typing.
func pause() -> void:
	_paused = true


func resume() -> void:
	_paused = false


func is_paused() -> bool:
	return _paused


func is_running() -> bool:
	return _running


func is_busy() -> bool:
	return _busy


## The type of the node holding the story, or nothing. What a game asks before deciding
## whether a click is its own. A name and not an enum, so an unknown type answers too.
func current_activity() -> StringName:
	if not _running or not _busy:
		return &""
	return StringName(graph.type_of(state.current_node()))


func has_errors() -> bool:
	for problem: MonologueProblem in problems:
		if problem.is_error():
			return true
	return false


## The three things that can happen to a node. It is entered, the game answers it, or a frame
## passes over it.
func _step(ctx: MonologueContext, delta: float) -> BehaviourResult:
	if not _busy:
		return _enter(ctx)

	if _answered_for == ctx.id:
		_answered_for = ""
		return behaviours.for_type(ctx.type).input(ctx)

	return _tick(ctx, delta)


func _on_answered() -> void:
	_answered_for = state.current_node()


func _enter(ctx: MonologueContext) -> BehaviourResult:
	for behaviour: MonologueBehaviour in behaviours.all():
		var taken: BehaviourResult = behaviour.step(ctx)
		if taken != null and not taken.is_waiting():
			return taken

	state.visit(ctx.id)
	state.step_index += 1
	_busy = true
	node_entered.emit(ctx.storyline, ctx.id)
	return behaviours.for_type(ctx.type).run(ctx)


## The behaviour holding the story first, then the watchers.
func _tick(ctx: MonologueContext, delta: float) -> BehaviourResult:
	var holder: MonologueBehaviour = behaviours.for_type(ctx.type)
	var result: BehaviourResult = holder.process(ctx, delta)
	if result != null and not result.is_waiting():
		return result

	for behaviour: MonologueBehaviour in behaviours.all():
		if behaviour == holder or not behaviour.active_process:
			continue
		result = behaviour.process(ctx, delta)
		if result != null and not result.is_waiting():
			return result
	return BehaviourResult.wait()


func _go(node_id: String) -> void:
	var next: String = node_id
	if next.is_empty():
		# Whoever pushed the return address needs to know which way out this is.
		state.ran_out_at = state.current_node()
		next = _unwind()

	if next.is_empty():
		state.ran_out_at = ""
		_end(&"story_ran_out")
		return
	if not graph.has_node(next):
		_fail(&"unknown_node", "The story points at '%s', which is gone." % next)
		return
	state.move_to(graph.storyline_of(next), next)


## Where the story goes when a chain runs out. The session only pops. What a node does when
## the story comes back to it is that node's business.
func _unwind() -> String:
	return str(state.call_stack.pop_back()) if not state.call_stack.is_empty() else ""


func _seed_variables() -> void:
	for record_id: String in graph.collections.get("variables", {}):
		state.variables[record_id] = graph.record("variables", record_id).get("value")


func _default_language() -> String:
	return graph.languages[0] if not graph.languages.is_empty() else ""


func _end(reason: StringName) -> void:
	if not state.ending.has("reason"):
		state.ending["reason"] = String(reason)
	_running = false
	_busy = false
	finished.emit()


func _fail(code: StringName, message: String) -> void:
	problems.append(
		MonologueProblem.error(code, message).at(state.current_node(), state.current_storyline())
	)
	push_error("Monologue: %s" % message)
	state.ending = {"reason": "error", "code": String(code), "message": message}
	_end(code)
