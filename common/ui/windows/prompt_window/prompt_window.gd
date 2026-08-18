class_name Prompt extends MonologueWindow

enum { CONFIRMED, DENIED, CANCELLED }

signal confirmed
signal denied
signal cancelled

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var confirm_button: Button = %ConfirmButton
@onready var deny_button: Button = %DenyButton
@onready var cancel_button: Button = %CancelButton

var _callback: Callable


func _ready() -> void:
	EventBus.ask_dialog.connect(_on_ask_request)
	EventBus.window_out.connect(_on_cancel_button_pressed)


func _on_confirm_button_pressed() -> void:
	hide()
	confirmed.emit()
	_callback_handler(Prompt.CONFIRMED)


func _on_deny_button_pressed() -> void:
	hide()
	denied.emit()
	_callback_handler(Prompt.DENIED)


func _on_cancel_button_pressed() -> void:
	if not visible:
		return

	hide()
	cancelled.emit()
	_callback_handler(Prompt.CANCELLED)


func _callback_handler(response: int) -> void:
	if not _callback:
		Log.error("Prompt window has no callback.")
		return

	if _callback.get_argument_count() < 1:
		Log.error("Invalid callback.")
		return

	_callback.call(response)


func _on_ask_request(
	callback: Callable,
	header: String,
	description: String,
	confirm_text: String = "Yes",
	deny_text: String = "No",
	cancel_text: String = "Cancel"
) -> void:
	_callback = callback

	title_label.text = header
	description_label.text = description
	confirm_button.text = confirm_text
	deny_button.text = deny_text
	cancel_button.text = cancel_text

	show()
