## Plays the project as it stands, in a window of its own.
##
## Nothing is written to disk first: the documents go straight from the live project into the
## addon, so an unsaved edit is what you watch. It is the shipped runtime doing the playing,
## not an editor-side imitation of it. What runs here is what a game
## running the same story would do.
class_name MonologueRunWindow extends Window

const DEFAULT_SIZE: Vector2i = Vector2i(960, 540)

var runtime: MonologueRuntime

var _player: MonologueDefaultPlayer


func _init() -> void:
	hide()
	force_native = true
	title = "Run"
	size = DEFAULT_SIZE
	content_scale_size = DEFAULT_SIZE
	content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND

	_player = MonologueDefaultPlayer.create()
	add_child(_player)

	runtime = MonologueRuntime.new()
	runtime.player = _player
	runtime.problem_reported.connect(_on_problem_reported)
	runtime.story_ended.connect(_on_story_ended)
	add_child(runtime)


func _ready() -> void:
	close_requested.connect(_on_close_requested)


## Restarts from the top every time, so pressing Run twice does what it looks like.
func play(project: MonologueProject, storyline_id: String = "", node_id: String = "") -> void:
	if not is_node_ready():
		await ready

	if not runtime.load_documents(ProjectWriter.documents_of(project)):
		Log.error("This story cannot be played; see the problems above.")
		return

	popup_centered()
	runtime.start(storyline_id, node_id)


func _on_story_ended(reason: String) -> void:
	Log.info("The story stopped: %s." % reason)


func _on_problem_reported(problem: MonologueProblem) -> void:
	if problem.is_error():
		Log.error(problem.message)
		return
	Log.warn(problem.message)


func _on_close_requested() -> void:
	runtime.stop()
	hide()
