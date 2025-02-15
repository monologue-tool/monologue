class_name MonologueToggle extends MonologueField


@onready var label = $Label
@onready var check_button = $Control/CheckButton


func set_label_text(text: String) -> void:
	label.text = text


func propagate(value: Variant) -> void:
	super.propagate(value)
	check_button.set_pressed_no_signal(value if value is bool else false)


func _on_check_button_toggled(toggled_on: bool) -> void:
	field_updated.emit(toggled_on)
