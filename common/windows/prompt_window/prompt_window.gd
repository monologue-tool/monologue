class_name PromptWindow extends MonologueWindow


signal confirmed
signal denied
signal cancelled

const SAVE_PROMPT = "%s has been modified."

@onready var title_label = %TitleLabel
@onready var description_label = %DescriptionLabel
@onready var confirm_button = %ConfirmButton
@onready var deny_button = %DenyButton
@onready var cancel_button = %CancelButton


func prompt_save(filename: String) -> void:
	if title_label:
		title_label.text = SAVE_PROMPT % Util.truncate_filename(filename.get_file())
		description_label.text = "The document you have opened will be closed. Do you want to save the changes?"
	GlobalSignal.emit("show_dimmer")
	show()


func _on_confirm_button_pressed() -> void:
	queue_free()
	confirmed.emit()


func _on_deny_button_pressed() -> void:
	queue_free()
	denied.emit()


func _on_cancel_button_pressed() -> void:
	queue_free()
	cancelled.emit()


func _on_tree_exited() -> void:
	GlobalSignal.emit("hide_dimmer")
