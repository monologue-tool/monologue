## What the story can ask of the game, and the one place an answer comes back through.
##
## Nothing here blocks. A method starts something and returns; when the game has answered,
## [signal answered] fires once and the behaviour holding the story is asked where to go. A
## player with no parts answers immediately, which is what a headless test wants and what a
## game gets before it has wired anything up.
##
## Replace a piece rather than the whole: inherit default_player.tscn, delete the part you do
## not want, drop in your own extending the matching Monologue*Part, and reassign the export.
class_name MonologuePlayer extends Node

## The game answered whatever was last asked. What it answered is on this player.
signal answered
## What an `action` node named, for a game that would rather listen than override [method act].
signal action_requested(action_name: String, arguments: Array)

@export var text_box: MonologueTextBoxPart
@export var choices: MonologueChoicePart
@export var characters: MonologueCharacterPart
@export var scenery: MonologueSceneryPart
@export var sound: MonologueSoundPart

## Where a path stored in the story is looked up from, when it is relative.
@export_dir var asset_root: String = ""

## The option last taken: the item id its wire leaves the choice node by.
var picked: String = ""
## What was last typed.
var answer: String = ""

## True between a question and its answer. A click landing on a line still on screen while
## some other node holds the story is not an answer, and must not read as one.
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


## [param options] is [{"key", "text", "speaker", "one_shot"}], already filtered and already
## worded by the behaviour. The answer lands in [member picked].
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


## Waits for the reader to move on without putting anything new on screen. What a node that
## only pauses asks for.
func acknowledge() -> void:
	asking = true
	if text_box == null:
		_answer()


## What an `action` node asks for. Override to do it; the default announces it and carries on.
func act(action_name: String, arguments: Array) -> Variant:
	action_requested.emit(action_name, arguments)
	return null


## A path as the story wrote it, made absolute.
func resolve(path: String) -> String:
	if path.is_empty() or path.is_absolute_path() or asset_root.is_empty():
		return path
	return asset_root.path_join(path).simplify_path()


## Takes the story off the screen. What a game calls when a run ends and the map comes back.
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


## Nothing was asked, so nothing was answered. Also what makes an answer arrive once: a part
## free to emit twice cannot move the story twice.
func _answer() -> void:
	if not asking:
		return
	asking = false
	answered.emit()
