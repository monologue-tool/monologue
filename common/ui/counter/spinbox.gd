extends PanelContainer

signal value_changed(value: Variant)

@export var as_integer: bool = true
@export var min_value: float = -9999999999
@export var max_value: float = 9999999999
@export var step: float = 1
@export var suffix: String

@onready var spin_box = $HBoxContainer/SpinBox

var value: Variant:
	get():
		return int(spin_box.value) if as_integer else spin_box.value
	set(value):
		spin_box.value = value


func _ready():
	var line_edit: LineEdit = spin_box.get_line_edit()
	line_edit.connect("focus_exited", _on_focus_exited)
	line_edit.connect("text_submitted", _on_text_submitted)
	line_edit.theme_type_variation = "SpinBoxLineEdit"
	_update_settings()


func _update_settings():
	spin_box.min_value = min_value
	spin_box.max_value = max_value
	spin_box.step = step
	spin_box.suffix = suffix


func _on_focus_exited() -> void:
	_on_text_submitted(int(spin_box.value) if as_integer else spin_box.value)


func _on_text_submitted(_new_value: Variant) -> void:
	value_changed.emit(int(spin_box.value) if as_integer else spin_box.value)


func _on_value_changed(_value: float) -> void:
	if as_integer:
		value_changed.emit(int(value))
	else:
		value_changed.emit(value)


func _on_decrease_button_pressed() -> void:
	spin_box.value -= spin_box.step
	_on_focus_exited.call_deferred()


func _on_increase_button_pressed() -> void:
	spin_box.value += spin_box.step
	_on_focus_exited.call_deferred()
