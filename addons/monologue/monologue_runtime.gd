## The one thing a game talks to.
## Written for a game that is not only a story: a run starts, ends, and the game carries on
## around it. The services outlive every run; the playthrough does not.
##
##     Monologue.load_project("res://story.mnlp")
##     Monologue.player = %DialogueLayer
##     Monologue.story_ended.connect(_on_story_ended)
##     Monologue.start()

class_name MonologueRuntime extends Node

signal story_started(storyline_id: String)
signal story_ended(reason: String)
signal node_entered(storyline_id: String, node_id: String)
signal problem_reported(problem: MonologueProblem)

var player: MonologuePlayer

var graph: MonologueStoryGraph
var session: MonologueSession
var services: MonologueServiceIndexer
var problems: Array[MonologueProblem] = []
var language: String = ""

var behaviours: MonologueBehaviourIndexer


func _ready() -> void:
	services = MonologueServiceIndexer.new(problems)
	add_child(services)
	behaviours = MonologueBehaviourIndexer.new(problems)
	add_child(behaviours)


## False when nothing playable came back.
func load_project(path: String) -> bool:
	return _adopt(MonologueSource.open(path))


## The same, from documents already in memory. What lets an editor play a story that has
## never been saved.
func load_documents(documents: Dictionary) -> bool:
	return _adopt(MonologueSource.of(documents))


## Loading replaces what came before, problems included: a story reloaded after a fix must
## not still be carrying the complaint that fix answered.
func _adopt(source: MonologueSource) -> bool:
	stop()
	problems.clear()
	graph = null

	var built: MonologueStoryGraph = MonologueStoryGraph.of(source)
	problems.append_array(built.problems)
	for problem: MonologueProblem in built.problems:
		problem_reported.emit(problem)

	if not source.is_readable:
		return false

	graph = built
	return not built.has_errors()


## Plays a storyline from its beginning, or from any node in it. Both arguments default to
## what the project says the story starts with.
func start(storyline_id: String = "", node_id: String = "") -> MonologueSession:
	if graph == null:
		_complain(&"no_project", "Nothing has been loaded, so there is nothing to play.")
		return null

	stop()
	services.clear_all()
	session = _new_session()
	add_child(session)

	# A story short enough to finish inside play() would otherwise report its ending first.
	var target: String = storyline_id if not storyline_id.is_empty() else graph.entry_storyline
	story_started.emit(target)

	session.play(storyline_id, node_id)
	return session


## Safe to call when nothing is playing, so a scene teardown can call it blind.
func stop() -> void:
	if session == null:
		return
	session.stop()
	_drop_session()


func pause() -> void:
	if session:
		session.pause()


func resume() -> void:
	if session:
		session.resume()


func is_idle() -> bool:
	return session == null or not session.is_running()


func is_paused() -> bool:
	return session != null and session.is_paused()


##     if Monologue.activity() == &"choice":
##         return  # the click belongs to the story, not to the map
func activity() -> StringName:
	return session.current_activity() if session else &""


func service(service_name: String) -> Object:
	return services.get_service(service_name)


## Hands the runtime something already in your scene. Any object will do: it only has to
## answer the calls the behaviours make on it.
func provide(service_name: String, object: Object) -> void:
	services.provide(service_name, object, problems)


## Where the story is, plus whatever every service kept. A game saved outside a story is a
## legal save.
func save() -> Dictionary:
	return {
		"story": session.snapshot() if session else {},
		"services": services.save_all(),
	}


## The story resumes at the top of the node it was on: a line half typed is not something a
## save file remembers.
func restore(data: Dictionary) -> void:
	if graph == null:
		_complain(&"no_project", "A save cannot be restored before a project is loaded.")
		return

	var story: Dictionary = data.get("story", {})
	if story.is_empty():
		stop()
		services.clear_all()
		services.load_all(data.get("services", {}))
		return

	if session == null:
		session = _new_session()
		add_child(session)

	session.restore(story)
	services.clear_all()
	services.load_all(data.get("services", {}))
	session.resume_here()


func has_errors() -> bool:
	for problem: MonologueProblem in problems:
		if problem.is_error():
			return true
	return false


func _new_session() -> MonologueSession:
	# A player with no parts answers everything at once.
	if player == null:
		player = MonologuePlayer.new()
		add_child(player)

	var made: MonologueSession = MonologueSession.new(
		graph, player, language, behaviours, services
	)
	made.node_entered.connect(node_entered.emit)
	made.finished.connect(_on_session_finished)
	return made


func _on_session_finished() -> void:
	var reason: String = str(session.state.ending.get("reason", "stopped")) if session else "stopped"
	story_ended.emit(reason)


func _drop_session() -> void:
	if session == null:
		return
	remove_child(session)
	session.queue_free()
	session = null


func _complain(code: StringName, message: String) -> void:
	var problem: MonologueProblem = MonologueProblem.error(code, message)
	problems.append(problem)
	push_error("Monologue: %s" % message)
	problem_reported.emit(problem)
