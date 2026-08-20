## What the story can ask of the game, and the one place an answer comes back through.
##
## Nothing here blocks. A method starts something and returns. When the game has answered,
## [signal answered] fires once and the behaviour holding the story is asked where to go.
##
## A player with no parts answers immediately, which is what a headless test wants and what a
## game gets before it has wired anything up.
##
## To replace one piece, inherit default_player.tscn, delete the part you do not want, drop in
## your own extending the matching Monologue*Part, and reassign the export.
class_name MonologuePlayer extends Node

## What it answered is on this player.
signal answered
## What an `action` node named, for a game that would rather listen than override
## [method act].
signal action_requested(action_name: String, arguments: Array)
## For an action the story is holding on. Whoever listens owes it a [method finish_action].
signal action_awaited(action_name: String, arguments: Array)

@export var text_box: MonologueTextBoxPart
@export var choices: MonologueChoicePart
@export var characters: MonologueCharacterPart
@export var scenery: MonologueSceneryPart
@export var sound: MonologueSoundPart

## Where a path stored in the story is looked up from, when it is relative.
@export_dir var asset_root: String = ""

## The option last taken, as the item id its wire leaves the choice node by.
var picked: String = ""
var answer: String = ""
## What the game answered the last waiting `action` with, under "value".
var _action_answer: Dictionary = {}

## True between a question and its answer. A click landing on a line still on screen while
## another node holds the story is not an answer.
var asking: bool = false


func _ready() -> void:
	if text_box:
		text_box.line_finished.connect(_answer)
		text_box.continued.connect(_answer)
		text_box.answer_given.connect(_on_answer_given)
	if choices:
		choices.option_picked.connect(_on_option_picked)

	show()


func show() -> void:
	for child: Node in get_children():
		if child is Control: child.show()


func hide() -> void:
	for child: Node in get_children():
		if child is Control: child.hide()


func say(
	line: String, speaker: String = "", tint: Color = Color.WHITE, voice: String = ""
) -> void:
	if sound and not voice.is_empty():
		sound.play_voice(resolve(voice))

	asking = true
	if text_box == null:
		_answer()
		return
	text_box.show_line(line, speaker, tint)


## [param options] is [{"key", "text", "speaker", "one_shot"}], already filtered and worded
## by the behaviour. The answer lands in [member picked].
func offer(options: Array[Dictionary]) -> void:
	asking = true
	if choices == null:
		picked = str(options[0]["key"]) if not options.is_empty() else ""
		_answer()
		return
	choices.show_options(options)


## The answer lands in [member answer].
func ask(prompt: String, placeholder: String = "", allow_empty: bool = false) -> void:
	asking = true
	if text_box == null:
		answer = ""
		_answer()
		return
	text_box.show_prompt(prompt, placeholder, allow_empty)


## Waits for the reader to move on without putting anything new on screen.
func acknowledge() -> void:
	asking = true
	if text_box == null:
		_answer()


## What an `action` node asks for. Override to do it. The default announces it and carries
## on. Whatever comes back is what the node keeps.
func act(action_name: String, arguments: Array) -> Variant:
	action_requested.emit(action_name, arguments)
	return null


## The same call with the story held until [method finish_action] answers it.
func await_act(action_name: String, arguments: Array) -> void:
	asking = true
	action_awaited.emit(action_name, arguments)

	# Nobody is listening, so nobody will ever answer.
	if action_awaited.get_connections().is_empty():
		finish_action(null)


func finish_action(result: Variant = null) -> void:
	_action_answer = {"value": result}
	_answer()


func action_result() -> Variant:
	return _action_answer.get("value")


## A path as the story wrote it, made absolute.
func resolve(path: String) -> String:
	if path.is_empty() or path.is_absolute_path() or asset_root.is_empty():
		return path
	return asset_root.path_join(path).simplify_path()


## Takes the story off the screen, for when a run ends and the game comes back.
func clear() -> void:
	asking = false
	if text_box:
		text_box.clear()
	if choices:
		choices.clear()


func _on_option_picked() -> void:
	picked = choices.picked
	choices.clear()
	_answer()


func _on_answer_given() -> void:
	answer = text_box.answer
	_answer()


## Nothing was asked, so nothing was answered. Also what makes an answer arrive once, so a
## part emitting twice cannot move the story twice.
func _answer() -> void:
	if not asking:
		return
	asking = false
	answered.emit()
