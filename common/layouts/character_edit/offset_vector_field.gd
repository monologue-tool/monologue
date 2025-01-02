extends HBoxContainer


@onready var x_spinbox := $HBoxContainer/HBoxContainer/SpinBox
@onready var y_spinbox := $HBoxContainer/HBoxContainer2/SpinBox
@onready var preview_section := %PreviewSection

var value: Array : set = _set_value, get = _get_value


func _set_value(val: Array) -> void:
	value = val
	x_spinbox.value = val[0]
	y_spinbox.value = val[1]

func _get_value() -> Array:
	return [x_spinbox.value, y_spinbox.value]
	

func _on_spin_box_value_changed(_value: float) -> void:
	preview_section.update_offset(value)
