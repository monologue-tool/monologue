## The dialogue box a game gets before it has written one.
##
## Click or press accept once to reveal the whole line, again to move on. That second press
## is what [signal line_finished] reports, so a story waits for its reader rather than
## running at typewriter speed.
class_name MonologueDefaultTextBox extends MonologueTextBoxPart

## Zero or less reveals the whole line at once.
@export var characters_per_second: float = 20.0

@export var speaker_container: Control
@export var speaker_label: Label
@export var body: RichTextLabel
@export var prompt: LineEdit
@export var next_indicator: Control

var _revealed: float = 0.0
var _revealing: bool = false
var _allow_empty: bool = false


func _ready() -> void:
	prompt.text_submitted.connect(_on_prompt_submitted)
	clear()


func show_line(line: String, speaker: String, tint: Color) -> void:
	prompt.hide()
	next_indicator.hide()
	show()
	speaker_label.text = speaker
	speaker_container.visible = not speaker.is_empty()
	speaker_label.add_theme_color_override(&"font_color", tint)

	body.text = line
	_revealed = 0.0
	_revealing = characters_per_second > 0.0
	body.visible_characters = 0 if _revealing else -1


func show_prompt(prompt_line: String, placeholder: String, allow_empty: bool) -> void:
	show_line(prompt_line, "", Color.WHITE)
	skip()
	_allow_empty = allow_empty
	prompt.text = ""
	prompt.placeholder_text = placeholder
	prompt.show()
	prompt.grab_focus()


func skip() -> void:
	_revealing = false
	body.visible_characters = -1


func clear() -> void:
	_revealing = false
	hide()
	prompt.hide()
	body.text = ""
	speaker_label.text = ""


func _process(delta: float) -> void:
	if not _revealing:
		return

	_revealed += delta * characters_per_second
	body.visible_characters = int(_revealed)
	if body.visible_ratio >= 1.0:
		skip()
		next_indicator.show()


## Nothing is consumed while a prompt is open: the LineEdit owns the keyboard then.
func _unhandled_input(event: InputEvent) -> void:
	if not visible or prompt.visible or not _is_advance(event):
		return

	get_viewport().set_input_as_handled()
	if _revealing:
		skip()
		return

	line_finished.emit()
	continued.emit()


static func _is_advance(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var click: InputEventMouseButton = event
		return click.pressed and click.button_index == MOUSE_BUTTON_LEFT
	return event.is_action_pressed(&"ui_accept")


func _on_prompt_submitted(text: String) -> void:
	if text.strip_edges().is_empty() and not _allow_empty:
		return

	answer = text
	prompt.hide()
	answer_given.emit()
