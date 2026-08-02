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

const ERROR_MODULATE: Color = Color(1, 0.85, 0.85, 1)
const WARNING_MODULATE: Color = Color(1, 0.95, 0.8, 1)

var _binding: FieldBinding
var _default_modulate: Color = Color(1, 1, 1, 1)

## Merged settings for the bound property. Always stored as a copy: aliasing the field
## type's shared defaults would let one widget's edit leak into every other instance.
var settings: Dictionary = {}:
	set(value):
		settings = value.duplicate(true)


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


## A field with no binding is one a composite widget drives itself, such as the value
## inside a condition. It has no property to name, and announcing is still its job.
func _describe() -> String:
	return _binding.property.name if _binding and _binding.property else "<detached>"


func emit_value_changed(value: Variant) -> void:
	Log.debug("Field value of property '%s' has changed." % _describe())
	value_changed.emit(value)


func emit_value_committed(value: Variant) -> void:
	Log.info("Field value of property '%s' has been committed." % _describe())
	value_committed.emit(value)


## Shows what is currently wrong with the value. Errors tint red, warnings amber, an
## empty list clears the marking. Override to render it better for a given widget.
##
## The value stays as the user typed it either way: validation annotates, it never
## takes the input back.
func display_issues(issues: Array[ValidationIssue]) -> void:
	if issues.is_empty():
		tooltip_text = ""
		modulate = _default_modulate
		return

	var messages: PackedStringArray = []
	var has_error: bool = false
	for issue: ValidationIssue in issues:
		messages.append(issue.message)
		has_error = has_error or issue.is_error()

	tooltip_text = "\n".join(messages)
	modulate = ERROR_MODULATE if has_error else WARNING_MODULATE


func clear_issues() -> void:
	display_issues([] as Array[ValidationIssue])


func set_preview() -> void:
	pass


func prefers_vertical_layout(_settings: Dictionary) -> bool:
	return false


@abstract func set_value(value: Variant) -> void
@abstract func get_value() -> Variant
@abstract func set_editable(is_editable: bool) -> void
