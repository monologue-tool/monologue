@abstract
class_name Field extends VBoxContainer

## Emitted on every real-time input change (keystroke, drag, slider move).
## FieldBinding uses this for live validation and error feedback only.
## The value is NOT persisted and does NOT create an undo/redo entry.
signal value_changed(new_value: Variant)

## Emitted when the user confirms the value (Enter, focus lost, item selected, drag end).
## FieldBinding persists the value into the Property, creating an undo/redo entry.
## This is the only signal that writes data to the model.
signal value_committed(new_value: Variant)

var _binding: FieldBinding
var _default_modulate: Color = Color(1, 1, 1, 1)

## Guard flag: true while this field is broadcasting its own snapshot value.
## FieldBinding checks this to avoid clobbering live data during emission.
var is_emitting_snapshot: bool = false

var settings: Dictionary = {}


func _ready() -> void:
	_default_modulate = modulate


func initialize(binding: FieldBinding = null) -> void:
	if binding:
		_binding = binding

	if _binding and _binding.property:
		var property: Property = _binding.property
		settings = property.get_settings()
	_on_initialize()


func _on_initialize() -> void:
	pass


func emit_value_changed(value: Variant) -> void:
	Log.debug("Field value of property '%s' has changed." % _binding.property.name)
	value_changed.emit(value)


func emit_value_committed(value: Variant) -> void:
	Log.info("Field value of property '%s' has been committed." % _binding.property.name)
	value_committed.emit(value)


func display_error(message: String) -> void:
	tooltip_text = message
	modulate = _default_modulate if message.is_empty() else Color(1, 0.85, 0.85, 1)


func clear_error() -> void:
	display_error("")


func after_commit(_value: Variant) -> void:
	pass


@abstract func set_value(value: Variant) -> void
@abstract func get_value() -> Variant
@abstract func set_editable(is_editable: bool) -> void
