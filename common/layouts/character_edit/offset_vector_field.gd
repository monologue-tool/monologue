extends HBoxContainer


@onready var x_spinbox := $HBoxContainer/HBoxContainer/SpinBox
@onready var y_spinbox := $HBoxContainer/HBoxContainer2/SpinBox

var value: Array : set = _set_value, get = _get_value


func _set_value(val: Array) -> void:
	value = val
	x_spinbox.value = val[0]
	y_spinbox.value = val[1]

func _get_value() -> Array:
	return [x_spinbox.value, y_spinbox.value]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
