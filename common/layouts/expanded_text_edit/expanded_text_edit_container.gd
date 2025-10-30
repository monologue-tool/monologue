## Container for expanded text editing with full screen overlay.
##
## Provides a larger text editing area that overlays the main UI, allowing
## users to edit text in a more spacious environment. Syncs changes back
## to the original small text edit.
extends MarginContainer

## Reference to the expanded text edit control.
@onready var text_edit: TextEdit = %TextEdit

## Reference to the original small text edit being expanded.
var little_text_edit: TextEdit


## Initializes the container and registers for expand signals.
func _ready() -> void:
	hide()
	GlobalSignal.add_listener("expand_text_edit", _on_expand_text_edit)


## Handles expand text edit requests.
##
## Copies text from the small text edit and shows the expanded editor.
## [br][br]
## [param little_te] The small text edit to expand.
func _on_expand_text_edit(little_te: TextEdit) -> void:
	little_text_edit = little_te
	text_edit.text = little_text_edit.text

	show()


## Handles the close button press.
##
## Hides the expanded editor and emits focus_exited on the original text edit.
func _on_button_pressed() -> void:
	hide()
	little_text_edit.focus_exited.emit()


## Syncs text changes from the expanded editor to the original.
##
## Updates the original text edit and emits its text_changed signal.
func _on_text_edit_text_changed() -> void:
	little_text_edit.text = text_edit.text
	little_text_edit.text_changed.emit()


## Handles visibility changes by showing/hiding the dimmer.
func _on_visibility_changed() -> void:
	if visible:
		GlobalSignal.emit("show_dimmer", [self])
		return
	GlobalSignal.emit("hide_dimmer", [self])
