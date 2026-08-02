## Shows whichever widget the current case calls for.
##
## The case comes from a sibling property. Written as "reference/property" it is read
## off the object that reference points at instead, which is how the value beside a
## variable takes the shape that variable declares.
class_name DynamicField extends Field

## Separates the reference property from the property to read on its target.
const TARGET_SEPARATOR: String = "/"

var _case_property: String = ""
var _cases: Dictionary = {}

@onready var field_container: HBoxContainer = %FieldContainer
var _field: Field


func set_value(value: Variant) -> void:
	if not is_node_ready():
		await ready

	if _field:
		_field.set_value(value)


func get_value() -> Variant:
	if _field:
		return _field.get_value()
	return null


func set_editable(is_editable: bool) -> void:
	if _field:
		_field.set_editable(is_editable)


func _on_initialize() -> void:
	super._on_initialize()

	_case_property = settings.get("case_property", "")
	_cases = settings.get("cases", {})

	_setup_property_case_listener()
	_update_case_field()


func _setup_property_case_listener() -> void:
	var case_property: Property = _case_source()
	if case_property == null:
		return

	if not case_property.value_changed.is_connected(_on_property_case_changed):
		case_property.value_changed.connect(_on_property_case_changed)

	# Reading through a reference means the target can change shape without this
	# property moving at all.
	var project: MonologueProject = ProjectManager.current_project
	if _reads_through_reference() and project:
		if not project.content_changed.is_connected(_update_case_field):
			project.content_changed.connect(_update_case_field)


func _reads_through_reference() -> bool:
	return TARGET_SEPARATOR in _case_property


## The property the case is watched on: the reference itself when reading through one.
func _case_source() -> Property:
	if not _binding or not _binding.owner:
		return null
	var path: String = _case_property.split(TARGET_SEPARATOR, true, 1)[0]
	return _binding.owner.get_property(path)


## The current case name, resolved either from a sibling or through a reference.
func _resolve_case() -> String:
	var source: Property = _case_source()
	if source == null:
		return ""
	if not _reads_through_reference():
		return str(source.get_value())

	return ReferenceResolver.resolve_property(
		ProjectManager.current_project,
		str(source.get_settings_value(PropertySettings.KEY_REFERENCE_SCOPE, "")),
		str(source.get_value()),
		_case_property.split(TARGET_SEPARATOR, true, 1)[1],
		_binding.owner
	)


func _update_case_field() -> void:
	for child: Node in field_container.get_children():
		child.queue_free()

	var actual_case: String = _resolve_case()
	if not _cases.has(actual_case):
		# Nothing chosen yet, or a target that no longer exists. Showing no widget is
		# better than showing one that writes the wrong kind of value.
		return
	var case_data: Dictionary = _cases[actual_case]
	var case_type: String = case_data.get("type")
	# TODO: honour case_data["default"] when the case has no stored value yet.
	# TODO: honour case_data["coerce"] to convert the value when the case changes.

	var new_field: Control = FieldWidgetFactory.create_or_placeholder(case_type)
	field_container.add_child(new_field)
	_field = null
	if new_field is Field:
		_field = new_field
		FieldWidgetFactory.bind_one(_binding.property, new_field, _binding.owner)


func _on_property_case_changed(_old_value: Variant, _new_value: Variant) -> void:
	_update_case_field()


func _exit_tree() -> void:
	var case_property: Property = _case_source()
	if case_property and case_property.value_changed.is_connected(_on_property_case_changed):
		case_property.value_changed.disconnect(_on_property_case_changed)

	var project: MonologueProject = ProjectManager.current_project
	if project and project.content_changed.is_connected(_update_case_field):
		project.content_changed.disconnect(_update_case_field)
