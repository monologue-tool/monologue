class_name MonologueVector extends MonologueField


@export var minimum: float = -9999999999
@export var maximum: float = 9999999999
@export var step: float = 1

@onready var label = $FieldLabel
@onready var x_spin_box := %XSpinBox
@onready var y_spin_box := %YSpinBox

var ribbon_scene = preload("res://common/ui/ribbon/ribbon.tscn")


func _ready() -> void:
	x_spin_box.min_value = minimum
	y_spin_box.min_value = minimum
	x_spin_box.max_value = maximum
	y_spin_box.max_value = maximum
	x_spin_box.step = step
	y_spin_box.step = step


func set_label_text(text: String) -> void:
	label.text = text


func propagate(value: Variant) -> void:
	super.propagate(value)
	x_spin_box.value = value[0] if (value[0] is float or value[0] is int) else 0
	y_spin_box.value = value[1] if (value[1] is float or value[1] is int) else 0


func _on_focus_exited() -> void:
	_on_spin_box_value_changed()


func _on_spin_box_value_changed(_value: float = 0.0) -> void:
	field_changed.emit([x_spin_box.value, y_spin_box.value])
