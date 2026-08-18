class_name Vector2Field extends Field

@onready var spinbox_x: SpinBox = %SpinBoxX
@onready var spinbox_y: SpinBox = %SpinBoxY


func _ready() -> void:
	spinbox_x.value_changed.connect(_on_spinbox_value_changed)
	spinbox_y.value_changed.connect(_on_spinbox_value_changed)


func set_value(value: Variant) -> void:
	if value is Array:
		spinbox_x.value = value[0]
		spinbox_y.value = value[1]
	elif value is Vector2:
		spinbox_x.value = value.x
		spinbox_y.value = value.y


func set_editable(is_editable: bool) -> void:
	spinbox_x.editable = is_editable
	spinbox_y.editable = is_editable


func get_value() -> Variant:
	return [spinbox_x.value, spinbox_y.value]


func _on_spinbox_value_changed(_value: float) -> void:
	emit_value_committed(get_value())
