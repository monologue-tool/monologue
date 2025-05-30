class_name MonologueSlider extends MonologueField


@export var default: float
@export var minimum: float
@export var maximum: float
@export var step: float
@export var suffix: String

@onready var control_label = $FieldLabel
@onready var spin_box = $HBoxContainer/SpinBox
@onready var reset_button = $HBoxContainer/ResetButton
@onready var slider = $HBoxContainer/HSlider

var skip_spin_box_update: bool = false


func _ready():
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	
	spin_box.min_value = minimum
	spin_box.max_value = maximum
	spin_box.step = step
	spin_box.suffix = suffix


func set_label_text(text: String) -> void:
	control_label.text = text


func propagate(value: Variant) -> void:
	super.propagate(value)
	slider.value = value if (value is float or value is int) else default


func _on_drag_ended(value_changed: bool) -> void:
	if value_changed:
		field_updated.emit(slider.value)


func _on_reset() -> void:
	if slider.value != default:
		slider.value = default
		field_updated.emit(default)


func _on_value_changed(value: float) -> void:
	skip_spin_box_update = true
	spin_box.value = value

func _on_spin_box_value_changed(value: float) -> void:
	if skip_spin_box_update:
		skip_spin_box_update = false
		return
	
	slider.value = value
	field_updated.emit(slider.value)
