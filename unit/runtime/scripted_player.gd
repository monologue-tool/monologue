## A player with no scene and no clock: it answers the moment it is asked, and keeps what the
## story asked for.
##
## This is what makes a headless test possible at all. A whole playthrough happens inside
## one `session.play()`, with no frames and no presentation. Set [member silent] to hold the
## story instead, the way a real player waiting on a reader does, and answer by hand.
class_name ScriptedPlayer extends MonologuePlayer

var said: Array[String] = []
## Every speaker named alongside them, same order.
var speakers: Array[String] = []
## Every set of options offered, as the keys they carried.
var offered: Array = []
## What to answer with, taken in order. An empty list takes the first option offered.
var answers: Array[String] = []
## Every action the story asked the game for.
var acted: Array[Dictionary] = []
## What to answer waiting actions with, taken in order. Empty answers with nothing.
var action_answers: Array = []
## How many times the story waited for the reader without showing anything new.
var acknowledged: int = 0

## Shows and waits rather than answering, so a test can watch a node being held.
var silent: bool = false

## The same three parts the player carries, named again so a test reads them without casting.
var staged: Staged
var backdrop: Backdrop
var audio: Audio


func _init() -> void:
	staged = Staged.new()
	backdrop = Backdrop.new()
	audio = Audio.new()
	characters = staged
	scenery = backdrop
	sound = audio
	for part: Node in [staged, backdrop, audio]:
		add_child(part)


func say(
	line: String, speaker: String = "", _tint: Color = Color.WHITE, _voice: String = ""
) -> void:
	said.append(line)
	speakers.append(speaker)
	_asked()


func offer(options: Array[Dictionary]) -> void:
	var keys: PackedStringArray = []
	for option: Dictionary in options:
		keys.append(str(option["key"]))
	offered.append(keys)

	if not answers.is_empty():
		picked = answers.pop_front()
	else:
		picked = keys[0] if not keys.is_empty() else ""
	_asked()


func ask(_prompt: String, _placeholder: String = "", _allow_empty: bool = false) -> void:
	answer = answers.pop_front() if not answers.is_empty() else ""
	_asked()


func acknowledge() -> void:
	acknowledged += 1
	_asked()


func act(action_name: String, arguments: Array) -> Variant:
	acted.append({"name": action_name, "arguments": arguments, "waited": false})
	return super(action_name, arguments)


## Answers with the next of [member action_answers]. Set [member silent] to hold instead.
func await_act(action_name: String, arguments: Array) -> void:
	acted.append({"name": action_name, "arguments": arguments, "waited": true})
	asking = true
	if silent:
		return
	finish_action(action_answers.pop_front() if not action_answers.is_empty() else null)


## Answers whatever is outstanding. What a test calls in place of a reader clicking.
func answer_now() -> void:
	_answer()


func _asked() -> void:
	asking = true
	if not silent:
		_answer()


## The three stage parts, each keeping what it was told instead of showing it.
class Staged extends MonologueCharacterPart:
	var applied: Array[Dictionary] = []
	var left: PackedStringArray = []
	var restaged: Dictionary = {}

	func apply(character: Dictionary, look: Dictionary) -> void:
		applied.append({"character": character, "look": look})

	func leave(character_id: String, _duration: float) -> void:
		left.append(character_id)

	func restage(stage: Dictionary) -> void:
		restaged = stage.duplicate(true)


class Backdrop extends MonologueSceneryPart:
	var images: PackedStringArray = []

	func show_image(path: String) -> void:
		images.append(path)


class Audio extends MonologueSoundPart:
	var played: Array[Dictionary] = []
	var voices: PackedStringArray = []
	var stopped: int = 0

	func play(path: String, loop: bool, volume_db: float, pitch: float) -> void:
		played.append({"path": path, "loop": loop, "volume": volume_db, "pitch": pitch})

	func play_voice(path: String) -> void:
		voices.append(path)

	func stop_all() -> void:
		stopped += 1
