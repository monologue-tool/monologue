## Lets a button's own text be edited in place on a double click.
##
## [codeblock]
## InlineRename.attach(button).committed.connect(_on_renamed)
## [/codeblock]
##
## While the edit is open the field stands where the button stood, and the button is hidden.
##
## Nothing is written here. The name is announced, and whoever attached this decides what it
## means and may refuse it. The button comes back saying what it said.
class_name InlineRename extends Node

## What the reader typed, once. Never empty, and never the name it already had.
signal committed(new_name: String)

## "FlatLineEdit" for a row that already draws its own box. Settable at any time.
var variation: StringName = &"":
	set(value):
		variation = value
		if _field:
			_field.theme_type_variation = value

var _button: Button
var _field: LineEdit
var _before: String = ""
var _editing: bool = false


static func attach(button: Button) -> InlineRename:
	var rename: InlineRename = InlineRename.new()
	rename._button = button
	button.add_child(rename)
	return rename


func _ready() -> void:
	_field = LineEdit.new()
	_field.theme_type_variation = variation
	_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field.text_submitted.connect(_on_submitted)
	_field.focus_exited.connect(_on_focus_exited)
	_field.gui_input.connect(_on_field_input)
	_field.hide()

	_button.add_child(_field)
	_button.gui_input.connect(_on_button_input)


## Starts the edit without waiting for a double click.
func open() -> void:
	var row: Node = _button.get_parent()
	if _editing or _field == null or row == null:
		return

	_editing = true
	_before = _button.text

	_field.custom_minimum_size.y = _button.size.y
	_field.text = _before

	_button.remove_child(_field)
	row.add_child(_field)
	row.move_child(_field, _button.get_index())
	_field.show()
	_button.hide()

	_field.grab_focus()
	_field.select_all()


func cancel() -> void:
	_close(false)


func _on_button_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return

	var click: InputEventMouseButton = event
	if click.double_click and click.button_index == MOUSE_BUTTON_LEFT:
		open()


## Escape puts the name back.
func _on_field_input(event: InputEvent) -> void:
	if _editing and event.is_action_pressed(&"ui_cancel"):
		_field.accept_event()
		cancel()


func _on_submitted(_text: String) -> void:
	_close(true)


## Clicking away agrees. Enter has already closed the edit by then, so this cannot commit a
## second time.
func _on_focus_exited() -> void:
	_close(true)


func _close(commit: bool) -> void:
	if not _editing:
		return

	_editing = false
	var written: String = _field.text.strip_edges()

	_field.hide()
	var row: Node = _field.get_parent()
	if row:
		row.remove_child(_field)
	_button.add_child(_field)
	_button.show()

	if commit and not written.is_empty() and written != _before:
		committed.emit(written)
