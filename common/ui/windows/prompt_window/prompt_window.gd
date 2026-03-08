class_name Prompt extends MonologueWindow

enum {
	CONFIRMED,
	DENIED,
	CANCELLED
}

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
	if _callback: _callback.call(Prompt.CONFIRMED)


func _on_deny_button_pressed() -> void:
	hide()
	denied.emit()
	if _callback: _callback.call(Prompt.DENIED)


func _on_cancel_button_pressed() -> void:
	hide()
	cancelled.emit()
	if _callback: _callback.call(Prompt.CANCELLED)


func _on_ask_request(callback: Callable, header: String, description: String, confirm_text: String = "Yes", deny_text: String = "No", cancel_text: String = "Cancel") -> void:
	_callback = callback
	
	title_label.text = header
	description_label.text = description
	confirm_button.text = confirm_text
	deny_button.text = deny_text
	cancel_button.text = cancel_text
	
	show()
