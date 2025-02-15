class_name MonologueCheckBox extends MonologueField


@onready var check_box = $Control/CheckBox
@onready var label = $Label


func set_label_text(text: String) -> void:
	label.text = text


func propagate(value: Variant) -> void:
	super.propagate(value)
	check_box.set_pressed_no_signal(value if (value is bool) else false)


func _on_check_box_toggled(toggled_on: bool) -> void:
	field_updated.emit(toggled_on)
