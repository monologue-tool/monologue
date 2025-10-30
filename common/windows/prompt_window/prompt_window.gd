## A prompt window for user confirmation with confirm/deny/cancel options.
##
## Provides a modal dialog for prompting users with a choice, such as
## saving changes before closing a document.
class_name PromptWindow extends MonologueWindow

## Emitted when the user confirms the prompt.
signal confirmed

## Emitted when the user denies the prompt.
signal denied

## Emitted when the user cancels the prompt.
signal cancelled

## Format string for save prompt title.
const SAVE_PROMPT = "%s has been modified."

## Reference to the title label.
@onready var title_label = %TitleLabel

## Reference to the description label.
@onready var description_label = %DescriptionLabel

## Reference to the confirm button.
@onready var confirm_button = %ConfirmButton

## Reference to the deny button.
@onready var deny_button = %DenyButton

## Reference to the cancel button.
@onready var cancel_button = %CancelButton


## Shows a save prompt for the specified filename.
##
## [param filename] The name of the file being saved.
func prompt_save(filename: String) -> void:
	if title_label:
		title_label.text = SAVE_PROMPT % Util.truncate_filename(filename.get_file())
		description_label.text = "The document you have opened will be closed. Do you want to save the changes?"
	show()


## Handles confirm button press.
##
## Frees the window and emits the confirmed signal.
func _on_confirm_button_pressed() -> void:
	queue_free()
	confirmed.emit()


## Handles deny button press.
##
## Frees the window and emits the denied signal.
func _on_deny_button_pressed() -> void:
	queue_free()
	denied.emit()


## Handles cancel button press.
##
## Frees the window and emits the cancelled signal.
func _on_cancel_button_pressed() -> void:
	queue_free()
	cancelled.emit()


## Hides the dimmer when the window exits the tree.
func _on_tree_exited() -> void:
	GlobalSignal.emit("hide_dimmer", [self])
