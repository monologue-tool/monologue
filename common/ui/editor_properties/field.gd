@abstract
class_name Field extends VBoxContainer

signal value_changed(new_value: Variant)
signal value_committed(new_value: Variant)

var _binding
var _default_modulate: Color = Color(1, 1, 1, 1)

var settings: Dictionary = {}


func _ready() -> void:
	_default_modulate = modulate


func initialize(binding: FieldBinding = null) -> void:
	if binding:
		_binding = binding
	_on_initialize()


func _on_initialize() -> void:
	pass


func emit_value_changed(value: Variant) -> void:
	value_changed.emit(value)


func emit_value_committed(value: Variant) -> void:
	value_committed.emit(value)


func set_editable(_is_editable: bool) -> void:
	pass


func display_error(message: String) -> void:
	tooltip_text = message
	modulate = _default_modulate if message.is_empty() else Color(1, 0.85, 0.85, 1)


func clear_error() -> void:
	display_error("")


func after_commit(_value: Variant) -> void:
	pass


@abstract func set_value(value: Variant) -> void
@abstract func get_value() -> Variant
