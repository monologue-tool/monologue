## A custom spinbox UI control with configurable behavior.
##
## Provides a number input with increment/decrement buttons, supporting
## both integer and floating-point values with customizable range and step.
extends PanelContainer

## Emitted when the spinbox value changes.
signal value_changed(value: Variant)

## Whether to treat values as integers (true) or floats (false).
@export var as_integer: bool = true

## Minimum allowed value.
@export var min_value: float = -9999999999

## Maximum allowed value.
@export var max_value: float = 9999999999

## Increment/decrement step size.
@export var step: float = 1

## Optional suffix to display after the value.
@export var suffix: String

## Reference to the internal SpinBox control.
@onready var spin_box = $HBoxContainer/SpinBox

## The current value of the spinbox.
var value: Variant:
	get():
		return int(spin_box.value) if as_integer else spin_box.value
	set(value):
		spin_box.value = value


## Initializes the spinbox and connects signals.
func _ready():
	var line_edit: LineEdit = spin_box.get_line_edit()
	line_edit.connect("focus_exited", _on_focus_exited)
	line_edit.connect("text_submitted", _on_text_submitted)
	line_edit.theme_type_variation = "SpinBoxLineEdit"
	_update_settings()


## Updates the internal spinbox with exported settings.
func _update_settings():
	spin_box.min_value = min_value
	spin_box.max_value = max_value
	spin_box.step = step
	spin_box.suffix = suffix


## Handles focus exit event and emits value change.
func _on_focus_exited() -> void:
	_on_text_submitted(int(spin_box.value) if as_integer else spin_box.value)


## Handles text submission and emits the value change signal.
func _on_text_submitted(_new_value: Variant) -> void:
	value_changed.emit(int(spin_box.value) if as_integer else spin_box.value)


## Handles value change events from the internal spinbox.
func _on_value_changed(_value: float) -> void:
	if as_integer:
		value_changed.emit(int(value))
	else:
		value_changed.emit(value)


## Decreases the spinbox value by the step amount.
func _on_decrease_button_pressed() -> void:
	spin_box.value -= spin_box.step
	_on_focus_exited.call_deferred()


## Increases the spinbox value by the step amount.
func _on_increase_button_pressed() -> void:
	spin_box.value += spin_box.step
	_on_focus_exited.call_deferred()
