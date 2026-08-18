@abstract
class_name Field extends VBoxContainer

## Every keystroke, drag and slider move. Nothing is persisted and no undo entry is made.
## FieldBinding uses it for live validation only.
signal value_changed(new_value: Variant)

## Enter, focus lost, item selected, drag end. The only signal that writes to the model, and
## the one that makes an undo entry.
signal value_committed(new_value: Variant)

const ERROR_MODULATE: Color = Color(1, 0.85, 0.85, 1)
const WARNING_MODULATE: Color = Color(1, 0.95, 0.8, 1)

var _binding: FieldBinding
var _default_modulate: Color = Color(1, 1, 1, 1)

## Always a copy. Aliasing the field type's shared defaults would let one widget's edit leak
## into every other instance.
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


## For the log. A field with no binding is one a composite widget drives itself, such as the
## value inside a condition.
func _bound_property_name() -> String:
	return _binding.property.name if _binding and _binding.property else "<detached>"


func emit_value_changed(value: Variant) -> void:
	Log.debug("Field value of property '%s' has changed." % _bound_property_name())
	value_changed.emit(value)


func emit_value_committed(value: Variant) -> void:
	Log.info("Field value of property '%s' has been committed." % _bound_property_name())
	value_committed.emit(value)


## Errors tint red, warnings amber, an empty list clears the marking. Override to render it
## better for a given widget.
##
## The value stays as the user typed it. Validation annotates, it never takes input back.
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


## An [OptionButton] is as wide as its longest entry by default, so one long name widens the
## whole panel.
static func fit_dropdown(button: OptionButton) -> void:
	if button == null:
		return
	button.fit_to_longest_item = false
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


@abstract func set_value(value: Variant) -> void
@abstract func get_value() -> Variant
@abstract func set_editable(is_editable: bool) -> void
