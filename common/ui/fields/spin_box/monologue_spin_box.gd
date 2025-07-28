class_name MonologueSpinBox extends MonologueField

@export var as_integer: bool = true
@export var minimum: float = -9999999999
@export var maximum: float = 9999999999
@export var step: float = 1
@export var suffix: String

@onready var spin_box = $CustomSpinBox


func _ready():
	spin_box.min_value = minimum
	spin_box.max_value = maximum
	spin_box.step = step
	spin_box.suffix = suffix
	spin_box._update_settings()


func propagate(value: Variant) -> void:
	super.propagate(value)
	spin_box.value = value if (value is float or value is int) else 0


func _on_custom_spin_box_value_changed(value: Variant) -> void:
	field_updated.emit(value)
